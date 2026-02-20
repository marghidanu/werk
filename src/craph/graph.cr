module Craph
  # Directed graph using an adjacency list representation.
  class Graph(T)
    def initialize
      @adjacency_list = Hash(T, Set(T)).new
    end

    # Add a new node to the graph
    def add_node(name : T)
      unless @adjacency_list.has_key?(name)
        @adjacency_list[name] = Set(T).new
      end
    end

    # Adds an edge between two nodes. If the nodes don't exist they will be automatically added.
    def add_edge(from : T, to : T)
      self.add_node(from)
      self.add_node(to)

      @adjacency_list[from].add(to)
    end

    # Get all nodes in the graph
    def nodes
      @adjacency_list.keys
    end

    # Returns the number of nodes in the graph
    def size
      @adjacency_list.size
    end

    # Check if the graph has no nodes
    def empty?
      @adjacency_list.empty?
    end

    # Check if a node exists in the graph
    def has_node?(name : T) : Bool
      @adjacency_list.has_key?(name)
    end

    # Check if an edge exists between two nodes
    def has_edge?(from : T, to : T) : Bool
      @adjacency_list.has_key?(from) && @adjacency_list[from].includes?(to)
    end

    # Get the neighbors of a node
    def neighbors(name : T) : Set(T)
      @adjacency_list[name]
    end
  end
end
