require "yaml"

module Werk::Model
  class Job
    include YAML::Serializable

    # The description for the job
    property description = ""

    # A list of variables to be passed to the job
    property variables = Hash(String, String).new

    # List commands
    property commands = Array(String).new

    # Dependencies list
    property needs = Array(String).new

    # Signals if the job is allowed to fail or not.
    property can_fail = false

    def initialize(@description, @commands)
    end
  end
end
