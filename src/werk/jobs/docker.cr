require "digest/md5"
require "log"

require "../../docr"

module Werk::Jobs
  class Docker < Werk::Config::Job
    @[YAML::Field(key: "image")]
    getter image = "alpine:latest"

    @[YAML::Field(key: "volumes")]
    getter volumes = Array(String).new

    @[YAML::Field(key: "entrypoint")]
    getter entrypoint = ["/bin/sh"]

    @[YAML::Field(key: "network_mode")]
    getter network_mode = "bridge"

    Log = ::Log.for(self)

    def run(session_id : UUID, name : String, context : String, variables : Hash(String, String)) : {Int32, String}
      script = script_file
      Log.debug { "Created temporary script file #{script.path}" }

      buffer_io = IO::Memory.new
      writers = Array(IO).new
      writers << buffer_io
      writers << Werk::Utils::PrefixIO.new(STDOUT, name) unless @silent
      output_io = IO::MultiWriter.new(writers)

      client = Docr::Client.new

      # Ensure the image is available locally
      if client.images.exists?(@image)
        Log.debug { "Image #{@image} was found locally" }
      else
        Log.debug { "Fetching image #{@image}" }
        repository, tag = Docr.parse_repository_tag(@image)
        client.images.pull(repository, tag)
      end

      # Create container
      container_name = "#{Digest::MD5.hexdigest(name)}-#{session_id}"
      Log.debug { "Creating container '#{container_name}'" }
      container = client.containers.create(
        container_name,
        Docr::ContainerConfig.new(
          image: @image,
          entrypoint: @entrypoint,
          cmd: ["/opt/start.sh"],
          working_dir: "/opt/workspace",
          env: variables.map { |k, v| "#{k}=#{v}" },
          host_config: Docr::HostConfig.new(
            network_mode: @network_mode,
            binds: [
              "#{script.path}:/opt/start.sh",
              "#{Path[context].expand}:/opt/workspace",
            ].concat(@volumes)
          ),
          labels: {
            "com.stuffo.werk.name"       => name,
            "com.stuffo.werk.session_id" => session_id.to_s,
          }
        )
      )

      begin
        Log.debug { "Starting container '#{container_name}'" }
        client.containers.start(container.id)

        Log.debug { "Streaming logs for '#{container_name}'" }
        client.containers.logs(container.id, output: output_io, follow: true, stdout: true, stderr: true)

        # Wait for the container execution to end and retrieve the exit code.
        status = client.containers.wait(container.id)
      ensure
        Log.debug { "Removing container '#{container_name}'" }
        client.containers.delete(container.id, force: true)
      end

      return {status.status_code, buffer_io.to_s}
    end
  end
end
