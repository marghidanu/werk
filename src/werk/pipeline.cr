module Werk
  class Pipeline
    Log = ::Log.for(self)

    SIGNALS = {Signal::INT, Signal::TERM}

    getter session_id = UUID.random
    getter scheduler : Werk::Scheduler
    getter? terminated = false

    def initialize(@config : Werk::Config)
      @scheduler = Werk::ParallelScheduler.new(@config)
      @active_executors = Array(Werk::Executors::Base).new
    end

    private def create_executor(job : Werk::Config::Job) : Werk::Executors::Base
      case job
      when Werk::Config::LocalJob  then Werk::Executors::Local.new
      when Werk::Config::DockerJob then Werk::Executors::Docker.new
      else
        raise Werk::Error.new("Unknown executor: #{job.class}")
      end
    end

    # Execute the target job and its dependencies according to the execution plan
    def run(
      target : String,
      cwd : String,
      variables : Werk::Variables,
      yes : Bool = false,
    )
      SIGNALS.each do |signal|
        signal.trap {
          Log.debug { "Captured #{signal}!" }
          terminate
        }
      end

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

        stage.each_slice(max_jobs).with_index do |batch, batch_id|
          break if @terminated

          batch.each_with_index do |name, job_id|
            job = @config.jobs[name]
            job_dotenv_vars, vault_passwords = Vault.load_dotenv_files(job.dotenv, vault_passwords)

            # Variable precedence (lowest to highest):
            # config → config dotenv → job → job dotenv → CLI → built-ins
            merged_vars = @config.variables
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
              })

            ctx = Werk::Context.new(
              session_id: @session_id,
              target: target,
              name: name,
              directory: cwd,
              stage_id: stage_id,
              batch_id: batch_id,
              variables: merged_vars,
            )

            spawn do
              executor = create_executor(job)
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
        end

        # If any of the jobs failed or pipeline was terminated, stop
        if exit_pipeline || @terminated
          Log.debug { "Exiting pipeline ahead of time!" }
          break
        end
      end

      PipelineResult.new(target: target, jobs: all_jobs)
    ensure
      SIGNALS.each(&.reset)
      Vault.wipe_passwords(vault_passwords) if vault_passwords
    end

    # Immediately terminate all running executors
    def terminate : Nil
      return if @terminated
      @terminated = true

      Log.debug { "Terminating all executors..." }
      @active_executors.each do |executor|
        executor.terminate
      rescue ex : Exception
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
      @created = Time.utc.to_unix_ms
    end

    def find_job?(name : String) : Werk::Executors::ExecutionResult?
      @jobs.find { |job| job.name == name }
    end

    def find_job(name : String) : Werk::Executors::ExecutionResult
      find_job?(name) || raise Werk::Error.new("Job '#{name}' not found in pipeline result")
    end

    def has_job?(name : String) : Bool
      @jobs.any? { |job| job.name == name }
    end

    def to_table : String
      Tallboy.table do
        header do
          cell "Name", align: :center
          cell "Stage", align: :center
          cell "Status", align: :center
          cell "Exit code", align: :center
          cell "Duration", align: :center
          cell "Executor", align: :center
        end

        @jobs.each do |job|
          row border: :bottom do
            cell job.name
            cell job.stage_id
            cell job.success? ? "OK".colorize(:green) : "Failed".colorize(:red), align: :center
            cell job.exit_code
            cell sprintf("%.3f secs", job.duration)
            cell job.executor
          end
        end
      end.to_s
    end
  end
end
