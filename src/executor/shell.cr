require "log"

require "../executor"

module Werk
  class Executor::Shell < Werk::Executor
    Log = ::Log.for(self)

    def run(job : Werk::Model::Job, session_id : UUID, name : String, context : String) : {Int32, String}
      job = job.as(Werk::Model::Job::Local)

      script = File.tempfile
      content = job.get_script_content
      File.write(script.path, content)
      File.chmod(script.path, 0o755)
      Log.debug { "Created temporary script file #{script.path}" }

      buffer_io = IO::Memory.new
      writers = Array(IO).new
      writers << buffer_io
      writers << Werk::Utils::PrefixIO.new(STDOUT, name) unless job.silent
      output_io = IO::MultiWriter.new(writers)

      Log.debug { "Starting Shell process ..." }
      process = Process.new(script.path,
        shell: true,
        env: job.variables,
        output: output_io,
        error: output_io,
        chdir: context,
      )

      status = process.wait

      return {status.exit_code, buffer_io.to_s}
    end
  end
end
