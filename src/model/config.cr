require "yaml"
require "uuid"

module Werk
  class Model::Config
    include YAML::Serializable

    @[YAML::Field(ignore: true)]
    property session_id = UUID.random

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
end
