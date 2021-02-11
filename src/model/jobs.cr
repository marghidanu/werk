require "docr"
require "log"
require "yaml"
require "uuid"

module Werk::Model
  abstract class Job
    include YAML::Serializable

    # The description for the job
    @[YAML::Field(key: "description")]
    property description = ""

    # A list of variables to be passed to the job
    @[YAML::Field(key: "variables")]
    property variables = Hash(String, String).new

    # List commands
    @[YAML::Field(key: "commands")]
    property commands = Array(String).new

    # Dependencies list
    @[YAML::Field(key: "needs")]
    property needs = Array(String).new

    # Signals if the job is allowed to fail or not.
    @[YAML::Field(key: "can_fail")]
    property can_fail = false

    # Suppress job output to STDOUT
    @[YAML::Field(key: "silent")]
    property silent = false

    @[YAML::Field(key: "executor")]
    property executor : String

    use_yaml_discriminator "executor", {
      local:  "Werk::Model::Job::Local",
      docker: "Werk::Model::Job::Docker",
    }

    def get_script_content
      [
        "#!/usr/bin/env sh",
        "set -o errexit",
        "set -o nounset",
      ].concat(@commands).join("\n")
    end

    abstract def run(session_id : UUID, name : String, context : String) : {Int32, String}
  end

  class Job::Docker < Job
    @[YAML::Field(key: "image")]
    property image = "alpine:latest"

    @[YAML::Field(key: "volumes")]
    property volumes = Array(String).new

    @[YAML::Field(key: "entrypoint")]
    property entrypoint = ["/bin/sh"]

    def run(session_id : UUID, name : String, context : String) : {Int32, String}
      script = File.tempfile
      content = self.get_script_content
      File.write(script.path, content)
      File.chmod(script.path, 0o755)

      buffer_io = IO::Memory.new
      writers = Array(IO).new
      writers << buffer_io
      writers << Werk::Utils::PrefixIO.new(STDOUT, name) unless @silent
      output_io = IO::MultiWriter.new(writers)

      client = Docr::Client.new
      api = Docr::API.new(client)

      # Pull image
      Log.debug { "Pulling image: #{@image}" }
      api.images.create(@image)

      # Create container
      Log.debug { "Creating container ..." }
      container_name = "#{name}-#{session_id}"
      container = api.containers.create(
        container_name,
        Docr::Types::CreateContainerConfig.new(
          image: @image,
          entrypoint: @entrypoint,
          cmd: ["/opt/start.sh"],
          working_dir: "/opt/workspace",
          env: @variables.map { |k, v| "#{k}=#{v}" },
          host_config: Docr::Types::HostConfig.new(
            binds: [
              "#{script.path}:/opt/start.sh",
              "#{Path[context].expand}:/opt/workspace",
            ].concat(@volumes)
          ),
          labels: {
            "com.stuffo.werk.name"       => "name",
            "com.stuffo.werk.session_id" => session_id.to_s,
          }
        )
      )

      begin
        Log.debug { "Starting container #{container_name} ..." }
        api.containers.start(container.id)

        Log.debug { "Getting logs for #{container_name} ..." }
        io = api.containers.logs(container.id, follow: true, stdout: true, stderr: true)

        # Reading the logs in the Docker format.
        # More information can be found here: https://docs.docker.com/engine/api/v1.41/#operation/ContainerAttach
        # Look for the "Stream format" section.
        loop do
          # Checking if there's any more incoming data
          break if io.peek.not_nil!.empty?

          # Reading the header
          _ = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
          frame_size = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)

          # Read frame and send it to the output IO
          slice = Bytes.new(frame_size)
          io.read(slice)
          output_io.write(slice)
        end

        # Wait for the container execution to end and retrieve the exit code.
        status = api.containers.wait(container.id)
      ensure
        Log.debug { "Removing container #{container_name}..." }
        api.containers.delete(container.id, force: true)
      end

      return {status.status_code, buffer_io.to_s}
    end
  end

  class Job::Local < Job
    def run(session_id : UUID, name : String, context : String) : {Int32, String}
      script = File.tempfile
      content = self.get_script_content
      File.write(script.path, content)
      File.chmod(script.path, 0o755)

      buffer_io = IO::Memory.new
      writers = Array(IO).new
      writers << buffer_io
      writers << Werk::Utils::PrefixIO.new(STDOUT, name) unless @silent
      output_io = IO::MultiWriter.new(writers)

      Log.debug { "Starting Shell process ..." }
      process = Process.new(". #{script.path}",
        shell: true,
        env: @variables,
        output: output_io,
        error: output_io,
        chdir: context,
      )

      status = process.wait

      return {status.exit_code, buffer_io.to_s}
    end
  end
end
