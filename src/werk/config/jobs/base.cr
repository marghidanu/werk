module Werk
  class Config
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

      # List of commands to execute
      @[YAML::Field(key: "commands")]
      getter commands : Array(String) = Array(String).new

      # Dependencies list
      @[YAML::Field(key: "needs")]
      getter needs : Array(String) = Array(String).new

      # Signals if the job is allowed to fail or not
      @[YAML::Field(key: "can_fail")]
      getter? can_fail : Bool = false

      # Suppress job output to STDOUT
      @[YAML::Field(key: "silent")]
      getter? silent : Bool = false

      # The executor type for this job
      @[YAML::Field(key: "executor")]
      getter executor : String

      # The shell interpreter to use
      @[YAML::Field(key: "interpreter")]
      getter interpreter : String = "/bin/sh"

      use_yaml_discriminator "executor", {
        local:  Werk::Config::LocalJob,
        docker: Werk::Config::DockerJob,
      }
    end
  end
end
