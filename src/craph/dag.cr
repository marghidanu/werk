module Craph
  class CycleError < Exception; end

  # Directed Acyclic Graph, extends Graph with cycle detection and topological sorting.
  class DAG(T) < Graph(T)
    # Check if the graph has no cycles using DFS
    def acyclic?
      visiting = Set(T).new
      visited = Set(T).new

      nodes.each do |node|
        return false unless dfs_acyclic?(node, visiting, visited)
      end

      true
    end

    # Return the nodes sorted topologically.
    # The algorithm uses clustered output to allow for parallel processing.
    def topological_sort : Array(Set(T))
      ba = Hash(T, Set(T)).new

      nodes.each do |node|
        ba[node] = Set(T).new unless ba.has_key?(node)

        neighbors(node).each do |neighbor|
          ba[neighbor] = Set(T).new unless ba.has_key?(neighbor)
          ba[node] << neighbor if node != neighbor
        end
      end

      result = Array(Set(T)).new
      loop do
        afters = ba.keys.select { |key| ba[key].empty? }
        break if afters.empty?

        result.unshift(afters.to_set)

        afters.each { |name| ba.delete(name) }
        ba.values.each do |value|
          afters.each { |name| value.delete(name) }
        end
      end

      raise CycleError.new("Graph has a cycle!") unless ba.empty?
      result
    end

    private def dfs_acyclic?(node : T, visiting : Set(T), visited : Set(T)) : Bool
      return true if visited.includes?(node)
      return false if visiting.includes?(node)

      visiting.add(node)

      neighbors(node).each do |neighbor|
        return false unless dfs_acyclic?(neighbor, visiting, visited)
      end

      visiting.delete(node)
      visited.add(node)
      true
    end
  end
end
