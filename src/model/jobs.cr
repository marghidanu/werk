require "yaml"

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

    abstract def run(name : String, context : String) : Werk::Model::Report::Job
  end

  class Job::Docker < Job
    @[YAML::Field(key: "image")]
    property image : String = "alpine:latest"

    def run(name : String, context : String) : Werk::Model::Report::Job
      Werk::Model::Report::Job.new(
        name: name,
        executor: @executor,
        variables: Hash(String, String).new,
        content: "",
        directory: context,
        exit_code: 0,
        output: "",
        duration: 0_f64
      )
    end
  end

  class Job::Local < Job
    def run(name : String, context : String) : Werk::Model::Report::Job
      script = File.tempfile
      content = self.get_script_content
      File.write(script.path, content)
      File.chmod(script.path, 0o755)

      buffer_io = IO::Memory.new
      writers = Array(IO).new
      writers << buffer_io
      writers << Werk::Utils::PrefixIO.new(STDOUT, name) unless @silent
      output_io = IO::MultiWriter.new(writers)

      process = Process.new(". #{script.path}",
        shell: true,
        env: @variables,
        output: output_io,
        error: output_io,
        chdir: context,
      )

      start = Time.local
      status = process.wait
      duration = Time.local - start

      Werk::Model::Report::Job.new(
        name: name,
        executor: @executor,
        variables: @variables,
        content: content,
        directory: context,
        exit_code: status.exit_code,
        output: buffer_io.to_s,
        duration: duration.total_seconds
      )
    end
  end
end
