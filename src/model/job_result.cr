require "json"

module Werk::Model
  class JobResult
    include JSON::Serializable

    # Job name
    property name : String

    # All variables passed to the job
    property variables : Hash(String, String)

    # Job script content
    property content : String

    # The directory in which the job was executed
    property directory : String

    # Execution exit code
    property exit_code : Int32

    # Job output (stdout & sterr combined)
    property output : String

    # Duration of the job execution
    property duration : Float64

    def initialize(@name, @variables, @content, @directory, @exit_code, @output, @duration)
    end
  end
end
