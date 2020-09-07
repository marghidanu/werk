module Werk::Utils
  # Minimal implementation for a Directed Acyclic Graph.
  class Graph
    # Creates a new empty graph. The implementation uses an adjacency list representation for the graph.
    def initialize
      @adjacency_list = Hash(String, Set(String)).new
    end

    # Add a new vertex to the graph
    def add_vertex(name : String)
      @adjacency_list[name] = Set(String).new if !@adjacency_list.has_key?(name)
    end

    # Adds an edge between two vertices. If the vertices don't exist they will be automatically added.
    def add_edge(from : String, to : String)
      self.add_vertex(from)
      self.add_vertex(to)

      @adjacency_list[from].add(to)
    end

    # Get all vertices for the graph
    def get_vertices
      @adjacency_list.keys
    end

    # Return the vertices of the graph sorted topologically.
    # The algorithm uses clustered output to allow for parallel processing.
    def topological_sort
      ba = Hash(String, Set(String)).new

      @adjacency_list.each do |key, values|
        ba[key] = Set(String).new if !ba.has_key?(key)

        values.each do |value|
          ba[value] = Set(String).new if !ba.has_key?(value)
          ba[key] << value if key != value
        end
      end

      result = Array(Array(String)).new
      loop do
        afters = ba.keys.select { |key| ba[key].empty? }
        break if afters.empty?

        result.unshift(afters.sort)

        afters.each { |name| ba.delete(name) }
        ba.values.each do |value|
          afters.each { |name| value.delete(name) }
        end
      end

      raise "Graph has a cycle!" if !ba.empty?
      result
    end
  end
end
