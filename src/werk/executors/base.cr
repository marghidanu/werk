module Werk::Executors
  ABNORMAL_EXIT = 255

  abstract class Base
    getter interpolation : Template::Interpolation = Template::Interpolation.new

    def execute(
      ctx : Werk::Context,
      job_config : Werk::Config::Job,
    ) : ExecutionResult
      # Expand variable references.
      interpolation.expand(ctx.variables)

      buffer_io = IO::Memory.new
      writers = [buffer_io] of IO
      writers.push(Werk::Utils::PrefixIO.new(STDOUT, ctx.name)) unless job_config.silent?
      output_io = IO::MultiWriter.new(writers, sync_close: true)

      start = Time.instant
      begin
        exit_code = perform(ctx, job_config, output_io)
      rescue ex : Exception
        Log.error { "Job #{ctx.name} failed. Exception: #{ex.message}" }
        exit_code = ABNORMAL_EXIT
      ensure
        output_io.close
      end
      duration = (Time.instant - start).total_seconds

      ExecutionResult.new(
        name: ctx.name,
        executor: job_config.executor,
        variables: interpolation.variables,
        directory: ctx.directory,
        stage_id: ctx.stage_id,
        batch_id: ctx.batch_id,
        exit_code: exit_code,
        output: Werk::Utils::Redactor.redact(buffer_io.to_s),
        duration: duration,
      )
    end

    protected abstract def perform(
      ctx : Werk::Context,
      job_config : Werk::Config::Job,
      output : IO,
    ) : Int32

    abstract def terminate : Nil
  end

  class ExecutionResult
    include JSON::Serializable

    getter name : String
    getter executor : String

    @[JSON::Field(ignore: true)]
    getter variables : Hash(String, String)

    @[JSON::Field(key: "variables")]
    getter masked_variables : Hash(String, String)

    getter directory : String
    getter stage_id : Int32
    getter batch_id : Int32
    getter exit_code : Int32
    getter output : String
    getter duration : Float64

    def initialize(
      @name,
      @executor,
      @variables,
      @directory,
      @stage_id,
      @batch_id,
      @exit_code,
      @output,
      @duration,
    )
      @masked_variables = @variables.transform_values { "***" }
    end

    def success? : Bool
      @exit_code == 0
    end
  end
end
