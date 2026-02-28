module Werk::Executors
  ABNORMAL_EXIT = 255

  abstract class Base
    @@shellcheck_scanner_initialized = false
    @@shellcheck_scanner : ShellCheck::Scanner?

    protected def self.shellcheck_scanner : ShellCheck::Scanner?
      unless @@shellcheck_scanner_initialized
        @@shellcheck_scanner_initialized = true
        @@shellcheck_scanner = ShellCheck::Scanner.new
      end
      @@shellcheck_scanner
    rescue ShellCheck::Error
      nil
    end

    def execute(
      ctx : Werk::Context,
      job_config : Werk::Config::Job,
    ) : ExecutionResult
      buffer_io = IO::Memory.new
      writers = Array(IO).new
      writers << buffer_io
      writers << Werk::Utils::PrefixIO.new(STDOUT, ctx.name) unless job_config.silent?
      output_io = IO::MultiWriter.new(writers)

      start = Time.instant
      begin
        exit_code = run_shellcheck(job_config, output_io) || perform(ctx, job_config, output_io)
      rescue ex : Exception
        Log.error { "Job #{ctx.name} failed. Exception: #{ex.message}" }
        exit_code = ABNORMAL_EXIT
      end
      duration = (Time.instant - start).total_seconds

      ExecutionResult.new(
        name: ctx.name,
        executor: job_config.executor,
        variables: ctx.variables,
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

    private def run_shellcheck(job_config : Werk::Config::Job, output : IO) : Int32?
      return nil if job_config.shellcheck.off?

      shell = ShellCheck::Scanner.shell_name(job_config.interpreter)
      scanner = self.class.shellcheck_scanner
      return nil unless shell && scanner

      findings = scanner.scan(job_config.script_content, shell)
      return nil if findings.empty?

      findings.each do |finding|
        output.puts "SC#{finding.code} (#{finding.level}) line #{finding.line}: #{finding.message}"
      end

      if job_config.shellcheck.strict? && findings.any? { |finding| finding.level == "error" || finding.level == "warning" }
        return 1
      end

      nil
    end
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
