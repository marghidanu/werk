module Werk
  class Pipeline
    Log = ::Log.for(self)

    getter session_id = UUID.random
    getter? terminated = false

    def initialize(
      @config : Werk::Config,
      scheduler : Werk::Scheduler? = nil,
    )
      @scheduler = scheduler || Werk::ParallelScheduler.new(@config)
      @executors = {
        "local"  => Werk::Executors::Local.new.as(Werk::Executors::Base),
        "docker" => Werk::Executors::Docker.new.as(Werk::Executors::Base),
      }
    end

    # Get the execution plan (delegates to scheduler)
    def get_plan(target : String) : Array(Set(String))
      @scheduler.get_plan(target)
    end

    # Execute the target job and its dependencies according to the execution plan
    def run(
      target : String,
      cwd : String,
      variables : Hash(String, String),
      yes : Bool = false,
    )
      Log.debug { "Retrieve execution plan for '#{target}'" }
      plan = get_plan(target)

      raise "Max parallel jobs must be greater than 0!" if @config.max_jobs < 1

      dotenv_vars = @config.dotenv.reduce(Hash(String, String).new) do |acc, file|
        acc.merge(Dotenv.load(file))
      end

      all_jobs = Array(Werk::Executors::ExecutionResult).new

      Log.debug { "Running pipeline with max_jobs set to #{@config.max_jobs}" }
      plan.each_with_index do |stage, stage_id|
        break if @terminated

        results = Channel(Werk::Executors::ExecutionResult).new
        exit_pipeline = false

        batch_id = 0
        stage.each_slice(@config.max_jobs) do |batch|
          break if @terminated

          batch.each_with_index do |name, job_id|
            job = @config.jobs[name]

            job_dotenv_vars = job.dotenv.reduce(Hash(String, String).new) do |acc, file|
              acc.merge(Dotenv.load(file))
            end
            executor = @executors[job.executor]? || raise "Unknown executor: #{job.executor}"

            ctx = Werk::Context.new(
              session_id: @session_id,
              target: target,
              name: name,
              directory: cwd,
              stage_id: stage_id,
              batch_id: batch_id,
              # Variable precedence (lowest to highest):
              # config → config dotenv → job → job dotenv → CLI → built-ins
              variables: @config.variables
                .merge(dotenv_vars)
                .merge(job.variables)
                .merge(job_dotenv_vars)
                .merge(variables)
                .merge({
                  "WERK_JOB_DESCRIPTION" => job.description,
                  "WERK_JOB_NAME"        => name,
                  "WERK_SESSION_ID"      => @session_id.to_s,
                  "WERK_SESSION_TARGET"  => target,
                  "WERK_STAGE_ID"        => stage_id.to_s,
                  "WERK_YES"             => yes.to_s,
                }),
            )

            spawn do
              Log.debug { "> Begin execution '#{name}' (#{stage_id}:#{batch_id}:#{job_id})" }
              result = executor.execute(ctx, job)
              results.send(result)
              Log.debug { "< End execution '#{name}' (#{stage_id}:#{batch_id}:#{job_id})" }
            end
          end

          batch.size.times do
            result = results.receive
            job = @config.jobs[result.name]
            all_jobs << result

            # Determining if we need to stop the pipeline
            exit_pipeline ||= (result.exit_code != 0) && !job.can_fail?
          end

          batch_id += 1
        end

        # If any of the jobs failed or pipeline was terminated, stop
        if exit_pipeline || @terminated
          Log.debug { "Exiting pipeline ahead of time!" }
          break
        end
      end

      PipelineResult.new(target: target, jobs: all_jobs)
    end

    # Immediately terminate all running executors
    def terminate : Nil
      return if @terminated
      @terminated = true

      Log.debug { "Terminating all executors..." }
      @executors.each_value do |executor|
        executor.terminate
      rescue ex
        Log.debug { "Error terminating executor: #{ex.message}" }
      end
    end
  end

  class PipelineResult
    include JSON::Serializable

    getter created : Int64
    getter target : String
    getter jobs : Array(Werk::Executors::ExecutionResult)

    def initialize(
      @target,
      @jobs = Array(Werk::Executors::ExecutionResult).new,
    )
      @created = Time.local.to_unix_ms
    end

    def find_job?(name : String) : Werk::Executors::ExecutionResult?
      @jobs.find { |job| job.name == name }
    end

    def find_job(name : String) : Werk::Executors::ExecutionResult
      find_job?(name) || raise "Job '#{name}' not found in pipeline result"
    end

    def has_job?(name : String) : Bool
      !find_job?(name).nil?
    end
  end
end
