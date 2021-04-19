require "json"

module Werk
  class Model::Report
    include JSON::Serializable

    # Unix epoch when this report was created
    property created : Int64

    # Target job name
    property target : String

    # Execution plan
    property plan : Array(Array(String))

    # Jobs results
    property jobs = Hash(String, Werk::Model::Report::Job).new

    def initialize(@target, @plan)
      @created = Time.local.to_unix_ms
    end
  end

  class Model::Report::Job
    include JSON::Serializable

    # Job name
    property name : String

    # Executor type
    property executor : String

    # All variables passed to the job
    property variables : Hash(String, String)

    # The directory in which the job was executed
    property directory : String

    # Execution exit code
    property exit_code : Int32

    # Job output (stdout & sterr combined)
    property output : String

    # Duration of the job execution
    property duration : Float64

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
