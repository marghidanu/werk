module Werk
  class Pipeline
    Log = ::Log.for(self)

    getter session_id = UUID.random
    getter scheduler : Werk::Scheduler
    getter? terminated = false

    def initialize(
      @config : Werk::Config,
      scheduler : Werk::Scheduler? = nil,
    )
      @scheduler = scheduler || Werk::ParallelScheduler.new(@config)
      @active_executors = Array(Werk::Executors::Base).new
    end

    private def create_executor(type : String) : Werk::Executors::Base
      case type
      when "local"  then Werk::Executors::Local.new
      when "docker" then Werk::Executors::Docker.new
      else               raise "Unknown executor: #{type}"
      end
    end

    # Execute the target job and its dependencies according to the execution plan
    def run(
      target : String,
      cwd : String,
      variables : Hash(String, String),
      yes : Bool = false,
    )
      Log.debug { "Retrieve execution plan for '#{target}'" }
      plan = @scheduler.get_plan(target)

      dotenv_vars, vault_passwords = Vault.load_dotenv_files(@config.dotenv)

      all_jobs = Array(Werk::Executors::ExecutionResult).new
      max_jobs = @config.max_jobs < 1 ? System.cpu_count.to_i32 : @config.max_jobs

      Log.debug { "Running pipeline with max_jobs set to #{max_jobs}" }
      plan.each_with_index do |stage, stage_id|
        break if @terminated

        results = Channel(Werk::Executors::ExecutionResult).new
        exit_pipeline = false

        batch_id = 0
        stage.each_slice(max_jobs) do |batch|
          break if @terminated

          batch.each_with_index do |name, job_id|
            job = @config.jobs[name]

            job_dotenv_vars, vault_passwords = Vault.load_dotenv_files(job.dotenv, vault_passwords)

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
              executor = create_executor(job.executor)
              @active_executors << executor

              begin
                Log.debug { "> Begin execution '#{name}' (#{stage_id}:#{batch_id}:#{job_id})" }
                result = executor.execute(ctx, job)
                results.send(result)
                Log.debug { "< End execution '#{name}' (#{stage_id}:#{batch_id}:#{job_id})" }
              ensure
                @active_executors.delete(executor)
              end
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
    ensure
      Vault.wipe_passwords(vault_passwords) if vault_passwords
    end

    # Immediately terminate all running executors
    def terminate : Nil
      return if @terminated
      @terminated = true

      Log.debug { "Terminating all executors..." }
      @active_executors.each do |executor|
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
