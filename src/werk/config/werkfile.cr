module Werk
  class Config
    include YAML::Serializable

    # Configuration file version.
    @[YAML::Field(key: "version")]
    getter version : String = "1"

    # Description for the configuration file
    @[YAML::Field(key: "description")]
    getter description : String = ""

    @[YAML::Field(key: "dotenv")]
    getter dotenv = Set(String).new

    # List of global variables
    @[YAML::Field(key: "variables")]
    getter variables = Hash(String, String).new

    @[YAML::Field(key: "max_jobs")]
    property max_jobs : Int32 = 0

    # Jobs available in the current configuration
    @[YAML::Field(key: "jobs")]
    getter jobs = Hash(String, Config::Job).new

    # Load configuration from file
    def self.load_file(path : String)
      raise Werk::Error.new("Configuration file missing!") unless File.exists?(path)

      content = File.read(path)
      self.load_string(content)
    end

    def self.load_string(content : String)
      raise Werk::Error.new("Empty configuration!") if content.empty?

      self.from_yaml(content)
    rescue ex : YAML::ParseException
      raise Werk::Error.new("Parse error at line #{ex.line_number}, column #{ex.column_number}")
    end
  end
end
