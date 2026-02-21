module Werk
  abstract class Scheduler
    def initialize(@config : Werk::Config)
    end

    abstract def get_plan(target : String) : Array(Set(String))

    private def build_graph(target : String) : Craph::DAG(String)
      graph = Craph::DAG(String).new
      traverse(target, graph)
      graph
    end

    private def traverse(
      name : String,
      graph : Craph::DAG(String),
      visited : Set(String) = Set(String).new,
    )
      raise "Job '#{name}' is not defined!" unless @config.jobs[name]?

      return if visited.includes?(name)
      visited << name

      graph.add_node(name)
      @config.jobs[name].needs.each do |dependency|
        graph.add_edge(dependency, name)
        traverse(dependency, graph, visited)
      end
    end
  end
end
