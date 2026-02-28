module Werk
  abstract class Scheduler
    def initialize(@config : Werk::Config)
    end

    abstract def get_plan(target : String) : Array(Set(String))

    protected def resolve_needs(job_name : String, needs : Array(String)) : Set(String)
      needs.flat_map { |dep|
        @config.jobs.keys.select { |name| name != job_name && File.match?(dep, name) }
      }.to_set
    end
  end
end
