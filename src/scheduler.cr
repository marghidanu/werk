require "./model/*"
require "./utils/*"
require "./executor/*"

module Werk
  class Scheduler
    # Initialize the Scheduler based on the configuration object
    def initialize(@config : Werk::Model::Config)
    end

    # Execute the target job and its dependencies according to he execution plan
    def run(target : String, context : String, max_parallel_jobs : Int32)
      plan = self.get_plan(target)

      if max_parallel_jobs < 1
        raise "Max parallel jobs must be greater than 0!"
      end

      report = Werk::Model::Report.new(
        target: target,
        plan: plan,
      )

      plan.each_with_index do |stage, stage_id|
        results = Channel(Werk::Model::JobResult).new

        stage.each_slice(max_parallel_jobs) do |batch|
          batch.each do |name|
            job = @config.jobs[name]

            variables = Hash(String, String).new
            variables.merge!(@config.variables)
            variables.merge!(job.variables)
            variables.merge!({
              "WERK_SESSION_TARGET"  => target,
              "WERK_STAGE_ID"        => stage_id.to_s,
              "WERK_JOB_NAME"        => name,
              "WERK_JOB_DESCRIPTION" => job.description || "",
            })
            job.variables = variables

            spawn do
              task = Werk::Executor::Shell.new
              result = task.run(name, job, context)
              results.send(result)
            end
          end

          batch.size.times do
            result = results.receive

            job = @config.jobs[result.name]
            report.jobs[result.name] = result

            if (result.exit_code != 0) && !job.can_fail
              raise "Job \"#{result.name}\" failed!"
            end
          end
        end
      end

      report
    end

    # Get execution plan based on the generated graph
    def get_plan(target : String)
      graph = Werk::Utils::Graph.new
      self.traverse(target, graph)

      graph.topological_sort
    end

    private def traverse(name : String, graph : Werk::Utils::Graph, visited = Set(String).new)
      unless @config.jobs[name]?
        raise "Job #{name} is not defined!"
      end

      return if visited.includes? name
      visited << name

      graph.add_vertex(name)
      @config.jobs[name].needs.each do |dependency|
        graph.add_edge(dependency, name)
        self.traverse(dependency, graph, visited)
      end
    end
  end
end
