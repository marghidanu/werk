module Werk
  abstract class Scheduler
    def initialize(@config : Werk::Config)
    end

    abstract def get_plan(target : String) : Array(Set(String))
  end
end
