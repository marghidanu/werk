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

      # Use Redirect::Pipe so we control the output copy fibers ourselves.
      # Crystal's internal copy fibers lack error handling, which causes
      # "Unhandled exception in spawn: Broken pipe" at process exit.
      process = Process.new(job_config.interpreter,
        args: ["-c", job_config.commands.join("\n")],
        shell: false,
        env: interpolation.variables,
        output: Process::Redirect::Pipe,
        error: Process::Redirect::Pipe,
        chdir: ctx.directory,
      )

      @process = process

      begin
        wg = WaitGroup.new
        {process.output, process.error}.each do |src|
          wg.spawn do
            IO.copy(src, output)
          rescue IO::Error
            nil
          end
        end

        status = process.wait
        wg.wait

        status.exit_code
      ensure
        @process = nil
      end
    end

    def terminate : Nil
      @process.try &.signal(Signal::TERM)
    rescue ex : RuntimeError
      Log.debug { "Failed to signal process: #{ex.message}" }
    end
  end
end
