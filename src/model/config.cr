require "yaml"
require "uuid"

module Werk
  class Model::Config
    include YAML::Serializable

    @[YAML::Field(ignore: true)]
    property session_id = UUID.random

    # Configuration file version.
    @[YAML::Field(key: "version")]
    property version = "1"

    # Description for the configuration file
    @[YAML::Field(key: "description")]
    property description = ""

    # List of global variables
    @[YAML::Field(key: "variables")]
    property variables = Hash(String, String).new

    # Jobs available in the current configuration
    @[YAML::Field(key: "jobs")]
    property jobs = Hash(String, Werk::Model::Job).new

    def initialize(@description, @jobs)
    end

    # Load configuration from file
    def self.load_file(path : String)
      raise "Configuration file missing!" unless File.exists?(path)

      content = File.read(path)
      self.load_string(content)
    end

    def self.load_string(content : String)
      raise "Configuration file is empty!" if content.empty?

      self.from_yaml(content)
    rescue yaml_ex : YAML::ParseException
      raise "Parse error at line #{yaml_ex.line_number}, column #{yaml_ex.column_number}"
    end
  end

  abstract class Model::Job
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
  end

  class Model::Job::Docker < Model::Job
    @[YAML::Field(key: "image")]
    property image = "alpine:latest"

    @[YAML::Field(key: "volumes")]
    property volumes = Array(String).new

    @[YAML::Field(key: "entrypoint")]
    property entrypoint = ["/bin/sh"]
  end

  class Model::Job::Local < Model::Job
  end
end
