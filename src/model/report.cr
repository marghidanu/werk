require "json"

module Werk::Model
  class Report
    include JSON::Serializable

    property created : Int64

    property target : String

    property plan : Array(Array(String))

    property jobs = Hash(String, Werk::Model::JobResult).new

    def initialize(@target, @plan)
      @created = Time.local.to_unix_ms
    end
  end
end
