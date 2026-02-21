module Werk
  class ParallelScheduler < Scheduler
    def get_plan(target : String) : Array(Set(String))
      build_graph(target).topological_sort
    end
  end
end
