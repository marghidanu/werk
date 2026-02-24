module Werk::Executors
  class Local < Base
    Log = ::Log.for(self)

    @process : Process?

    protected def perform(
      ctx : Werk::Context,
      job_config : Werk::Config::Job,
      output : IO,
    ) : Int32
      Log.debug { "Starting process with #{job_config.interpreter} -c ..." }
      process = Process.new(job_config.interpreter,
        args: ["-c", job_config.script_content],
        shell: false,
        env: ctx.variables,
        output: output,
        error: output,
        chdir: ctx.directory,
      )

      @process = process

      begin
        status = process.wait
        status.exit_code
      ensure
        @process = nil
      end
    end

    def terminate : Nil
      @process.try &.signal(Signal::TERM)
    rescue ex
      Log.debug { "Failed to signal process: #{ex.message}" }
    end
  end
end
