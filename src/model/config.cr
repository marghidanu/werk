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
  end
end
