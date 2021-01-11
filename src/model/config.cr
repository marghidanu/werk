require "yaml"

module Werk::Model
  class Config
    include YAML::Serializable

    # Configuration file version.
    property version = "1"

    # Description for the configuration file
    property description = ""

    # List of global variables
    property variables = Hash(String, String).new

    # Jobs available in the current configuration
    property jobs = Hash(String, Werk::Model::Job).new

    def initialize(@description, @jobs)
    end

    # Load configuration from file
    def self.load_file(path : String)
      unless File.exists?(path)
        raise "Configuration file missing!"
      end

      content = File.read(path)
      Werk::Model::Config.load_string(content)
    end

    def self.load_string(content : String)
      if content.empty?
        raise "Configuration file is empty!"
      end

      Werk::Model::Config.from_yaml(content)
    rescue yaml_ex : YAML::ParseException
      raise "Parse error at line #{yaml_ex.line_number}, column #{yaml_ex.column_number}"
    end
  end
end
