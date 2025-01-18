require "json"

module Werk
  class Report
    include JSON::Serializable

    # Unix epoch when this report was created
    getter created : Int64

    # Target job name
    getter target : String

    # Execution plan
    getter plan : Array(Array(String))

    # Jobs results
    getter jobs = Hash(String, Werk::Report::Job).new

    def initialize(@target, @plan)
      @created = Time.local.to_unix_ms
    end

    class Report::Job
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
        @duration,
      )
      end
    end
  end
end
