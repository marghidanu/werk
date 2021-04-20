require "log"

require "./model/*"
require "./utils/*"
require "./executor/*"

module Werk
  class Scheduler
    # Initialize the Scheduler based on the configuration object
    def initialize(@config : Werk::Model::Config)
    end

    # Execute the target job and its dependencies according to he execution plan
    def run(target : String, context : String, variables : Hash(String, String), max_parallel_jobs : Int32)
      plan = self.get_plan(target)

      raise "Max parallel jobs must be greater than 0!" if max_parallel_jobs < 1

      report = Werk::Model::Report.new(target: target, plan: plan)
      plan.each_with_index do |stage, stage_id|
        results = Channel(Werk::Model::Report::Job).new
        exit_pipeline = false

        stage.each_slice(max_parallel_jobs) do |batch|
          batch.each do |name|
            job = @config.jobs[name]

            vars = Hash(String, String).new
            vars.merge!(@config.variables)
            vars.merge!(job.variables)
            vars.merge!(variables)
            vars.merge!({
              "WERK_SESSION_ID"      => @config.session_id.to_s,
              "WERK_SESSION_TARGET"  => target,
              "WERK_STAGE_ID"        => stage_id.to_s,
              "WERK_JOB_NAME"        => name,
              "WERK_JOB_DESCRIPTION" => job.description || "",
            })
            job.variables = vars

            case job
            when Werk::Model::Job::Docker
              executor = Werk::Executor::Docker.new
            when Werk::Model::Job::Local
              executor = Werk::Executor::Shell.new
            else
              raise "Unknown executor type!"
            end

            spawn do
              start = Time.local
              begin
                exit_code, output = executor.run(job, @config.session_id, name, context)
              rescue ex
                Log.error { "Job #{name} failed. Exception: #{ex.message}" }

                # TODO: Move this outside try/catch block and make exit_code nillable
                exit_code, output = {255, ""}
              end
              duration = Time.local - start

              results.send(
                Werk::Model::Report::Job.new(
                  name: name,
                  executor: job.executor,
                  variables: job.variables,
                  directory: context,
                  exit_code: exit_code,
                  output: output,
                  duration: duration.total_seconds,
                )
              )
            end
          end

          batch.size.times do
            result = results.receive

            job = @config.jobs[result.name]
            report.jobs[result.name] = result

            # Determining if we need to stop the pipeline
            exit_pipeline = (result.exit_code != 0) && !job.can_fail
          end
        end

        # If any of the jobs failed, we stop the pipeline.
        break if exit_pipeline
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
      raise "Job #{name} is not defined!" unless @config.jobs[name]?

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
