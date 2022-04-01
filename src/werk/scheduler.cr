require "uuid"
require "log"
require "dotenv"

require "./config"
require "./report"
require "./jobs/*"
require "./utils/*"

module Werk
  class Scheduler
    Log = ::Log.for(self)

    getter session_id = UUID.random

    # Initialize the Scheduler based on the configuration object
    def initialize(@config : Werk::Config)
    end

    # Execute the target job and its dependencies according to he execution plan
    def run(target : String, context : String, variables : Hash(String, String))
      Log.debug { "Retrieve execution plan for '#{target}'" }
      plan = self.get_plan(target)

      raise "Max parallel jobs must be greater than 0!" if @config.max_jobs < 1

      Log.debug { "Running scheduler with max_jobs set to #{@config.max_jobs}" }
      @config.dotenv.each { |f| @config.variables.merge!(Dotenv.load(f)) }

      report = Werk::Report.new(target: target, plan: plan)
      plan.each_with_index do |stage, stage_id|
        results = Channel(Werk::Report::Job).new
        exit_pipeline = false

        batch_id = 0
        stage.each_slice(@config.max_jobs) do |batch|
          batch.each_with_index do |name, job_id|
            job = @config.jobs[name]

            job.dotenv.each { |f| job.variables.merge!(Dotenv.load(f)) }
            vars = Hash(String, String).new
            vars.merge!(@config.variables)
            vars.merge!(job.variables)
            vars.merge!(variables)
            vars.merge!({
              "WERK_SESSION_ID"      => @session_id.to_s,
              "WERK_SESSION_TARGET"  => target,
              "WERK_STAGE_ID"        => stage_id.to_s,
              "WERK_JOB_NAME"        => name,
              "WERK_JOB_DESCRIPTION" => job.description || "",
            })
            job.variables = vars

            spawn do
              start = Time.local
              begin
                Log.debug { "> Begin execution '#{name}' (#{stage_id}:#{batch_id}:#{job_id})" }
                exit_code, output = job.run(@session_id, name, context)
                Log.debug { "< End execution '#{name}' (#{stage_id}:#{batch_id}:#{job_id})" }
              rescue ex
                Log.error { "Job #{name} failed. Exception: #{ex.message}" }
                exit_code, output = {255, ""}
              end
              duration = Time.local - start

              results.send(
                Werk::Report::Job.new(
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

          batch_id += 1
        end

        # If any of the jobs failed, we stop the pipeline.
        if exit_pipeline
          Log.debug { "Exiting pipeline ahead of time!" }
          break
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
        raise "Job '#{name}' is not defined!"
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
