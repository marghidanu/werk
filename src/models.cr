require "yaml"
require "json"

module Werk
  class Model::Config
    include YAML::Serializable

    # Configuration file version.
    @[YAML::Field(key: "version")]
    getter version = "1"

    # Description for the configuration file
    @[YAML::Field(key: "description")]
    getter description = ""

    @[YAML::Field(key: "dotenv")]
    getter dotenv = Set(String).new

    # List of global variables
    @[YAML::Field(key: "variables")]
    property variables = Hash(String, String).new

    @[YAML::Field(key: "max_jobs")]
    property max_jobs : UInt32 = 32_u32

    # Jobs available in the current configuration
    @[YAML::Field(key: "jobs")]
    getter jobs = Hash(String, Werk::Model::Job).new

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
    getter description = ""

    # List of dotenv files to be loaded
    @[YAML::Field(key: "dotenv")]
    getter dotenv = Set(String).new

    # A list of variables to be passed to the job
    @[YAML::Field(key: "variables")]
    property variables = Hash(String, String).new

    # List commands
    @[YAML::Field(key: "commands")]
    getter commands = Array(String).new

    # Dependencies list
    @[YAML::Field(key: "needs")]
    getter needs = Array(String).new

    # Signals if the job is allowed to fail or not.
    @[YAML::Field(key: "can_fail")]
    getter can_fail = false

    # Suppress job output to STDOUT
    @[YAML::Field(key: "silent")]
    getter silent = false

    @[YAML::Field(key: "executor")]
    getter executor : String

    @[YAML::Field(key: "interpreter")]
    getter interpreter = "/bin/sh"

    use_yaml_discriminator "executor", {
      local:  Werk::Job::Local,
      docker: Werk::Job::Docker,
    }

    abstract def run(session_id : UUID, name : String, context : String) : {Int32, String}

    def get_script_content
      [
        "#!#{@interpreter}",
      ].concat(@commands).join("\n")
    end
  end

  class Model::Report
    include JSON::Serializable

    # Unix epoch when this report was created
    getter created : Int64

    # Target job name
    getter target : String

    # Execution plan
    getter plan : Array(Array(String))

    # Jobs results
    getter jobs = Hash(String, Werk::Model::Report::Job).new

    def initialize(@target, @plan)
      @created = Time.local.to_unix_ms
    end
  end

  class Model::Report::Job
    include JSON::Serializable

    # Job name
    getter name : String

    # Executor type
    getter executor : String

    # All variables passed to the job
    getter variables : Hash(String, String)

    # The directory in which the job was executed
    getter directory : String

    # Execution exit code
    getter exit_code : Int32

    # Job output (stdout & sterr combined)
    getter output : String

    # Duration of the job execution
    getter duration : Float64

    def initialize(
      @name,
      @executor,
      @variables,
      @directory,
      @exit_code,
      @output,
      @duration
    )
    end
  end
end
