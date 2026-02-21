module Werk
  class SequentialScheduler < Scheduler
    def get_plan(target : String) : Array(Set(String))
      build_graph(target).topological_sort.flat_map do |stage|
        stage.map { |job| Set{job} }
      end
    end
  end
end
