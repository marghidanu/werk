require "json"

module Werk::Model
  class Report
    include JSON::Serializable

    # Unix epoch when this report was created
    property created : Int64

    # Target job name
    property target : String

    # Execution plan
    property plan : Array(Array(String))

    # Jobs results
    property jobs = Hash(String, Werk::Model::JobResult).new

    def initialize(@target, @plan)
      @created = Time.local.to_unix_ms
    end
  end
end
