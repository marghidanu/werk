module Werk::Executors
  class Local < Base
    Log = ::Log.for(self)

    def initialize
      @running_processes = Array(Process).new
    end

    protected def perform(
      ctx : Werk::Context,
      job : Werk::Config::Job,
      output : IO,
    ) : Int32
      Log.debug { "Starting process with #{job.interpreter} -c ..." }
      process = Process.new(job.interpreter,
        args: ["-c", job.script_content],
        shell: false,
        env: ctx.variables,
        output: output,
        error: output,
        chdir: ctx.directory,
      )

      @running_processes << process

      begin
        status = process.wait
        status.exit_code
      ensure
        @running_processes.delete(process)
      end
    end

    def terminate : Nil
      @running_processes.each do |process|
        process.signal(Signal::TERM)
      rescue ex
        Log.debug { "Failed to signal process: #{ex.message}" }
      end

      @running_processes.clear
    end
  end
end
