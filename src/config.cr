require "yaml"

module Werk
  class Config
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
    getter jobs = Hash(String, Config::Job).new

    # Load configuration from file
    def self.load_file(path : String)
      unless File.exists?(path)
        raise "Configuration file missing!"
      end

      content = File.read(path)
      self.load_string(content)
    end

    def self.load_string(content : String)
      if content.empty?
        raise "Empty configuration!"
      end

      self.from_yaml(content)
    rescue yaml_ex : YAML::ParseException
      raise "Parse error at line #{yaml_ex.line_number}, column #{yaml_ex.column_number}"
    end

    abstract class Job
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

      def get_script_file
        script = File.tempfile
        content = get_script_content
        File.write(script.path, content)
        File.chmod(script.path, 0o755)

        script
      end
    end
  end
end
