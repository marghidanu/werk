module Template
  class Interpolation
    VARIABLE_PATTERN = /\$\$|\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}/

    getter variables : Hash(String, String) = Hash(String, String).new

    # Replaces `${VAR}` references in *template* with their values.
    # Undefined variables are left as-is; `$$` is escaped to a single `$`.
    def interpolate(template : String) : String
      substitute(template, @variables)
    end

    # Interpolates every string in *templates*. Returns a new array.
    def interpolate_all(templates : Array(String)) : Array(String)
      templates.map { |tmpl| interpolate(tmpl) }
    end

    # Expands variable cross-references using topological sort.
    # Raises `Craph::CycleError` if any circular references are detected.
    def expand(variables : Hash(String, String)) : self
      # Build a dependency graph: edge from dependency → dependent
      graph = Craph::DAG(String).new
      variables.each_key { |name| graph.add_node(name) }

      variables.each do |name, value|
        value.scan(VARIABLE_PATTERN) do |match_data|
          next unless match_data[1]?

          dep = match_data[1]
          raise Craph::CycleError.new("Variable '#{name}' references itself") if dep == name

          graph.add_edge(dep, name)
        end
      end

      # Resolve in topological order (leaves first).
      # Raises if cyclic references exist.
      graph.topological_sort.each do |group|
        group.each do |name|
          next unless variables.has_key?(name)
          variables[name] = substitute(variables[name], variables)
        end
      end

      @variables = variables
      self
    end

    private def substitute(template : String, vars : Hash(String, String)) : String
      template.gsub(VARIABLE_PATTERN) do |match, match_data|
        match_data[1]? ? (vars[match_data[1]]? || match) : "$"
      end
    end
  end
end
