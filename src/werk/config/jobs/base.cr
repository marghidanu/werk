module Werk
  class Config
    enum ShellCheckMode
      Off
      Warn
      Strict
    end

    abstract class Job
      include YAML::Serializable

      # The description for the job
      @[YAML::Field(key: "description")]
      getter description : String = ""

      # List of dotenv files to be loaded
      @[YAML::Field(key: "dotenv")]
      getter dotenv : Set(String) = Set(String).new

      # A list of variables to be passed to the job
      @[YAML::Field(key: "variables")]
      getter variables : Hash(String, String) = Hash(String, String).new

      # List commands
      @[YAML::Field(key: "commands")]
      getter commands : Array(String) = Array(String).new

      # Dependencies list
      @[YAML::Field(key: "needs")]
      getter needs : Array(String) = Array(String).new

      # Signals if the job is allowed to fail or not.
      @[YAML::Field(key: "can_fail")]
      getter? can_fail : Bool = false

      # Suppress job output to STDOUT
      @[YAML::Field(key: "silent")]
      getter? silent : Bool = false

      @[YAML::Field(key: "executor")]
      getter executor : String

      @[YAML::Field(key: "interpreter")]
      getter interpreter : String = "/bin/sh"

      @[YAML::Field(key: "shellcheck")]
      getter shellcheck : Config::ShellCheckMode = Config::ShellCheckMode::Off

      def script_content : String
        commands.join("\n")
      end

      use_yaml_discriminator "executor", {
        local:  Werk::Config::LocalJob,
        docker: Werk::Config::DockerJob,
      }
    end
  end
end
