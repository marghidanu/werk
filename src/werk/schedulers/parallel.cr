module Werk
  class ParallelScheduler < Scheduler
    def get_plan(target : String) : Array(Set(String))
      graph = Craph::DAG(String).new
      stack = [target]
      visited = Set(String).new

      while name = stack.pop?
        raise Werk::Error.new("Job '#{name}' is not defined!") unless @config.jobs[name]?
        next if visited.includes?(name)
        visited << name

        graph.add_node(name)
        @config.jobs[name].needs.each do |dependency|
          graph.add_edge(dependency, name)
          stack << dependency
        end
      end

      graph.topological_sort
    end
  end
end
