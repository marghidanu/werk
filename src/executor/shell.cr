require "../utils/*"

module Werk::Executor
  class Shell < Werk::Executor::Base
    def run(name : String, job : Werk::Model::Job, context : String) : Werk::Model::JobResult
      content = [
        "#!/bin/sh",
        "set -o errexit",
        "set -o nounset",
      ]
      content.concat(job.commands)

      script = File.tempfile
      File.write(script.path, content.join("\n"))
      File.chmod(script.path, 0o755)

      buffer_io = IO::Memory.new

      writers = Array(IO).new()
      writers << buffer_io
      writers << Werk::Utils::PrefixIO.new(STDOUT, name) unless job.silent
      output_io = IO::MultiWriter.new(writers)

      process = Process.new(". #{script.path}",
        shell: true,
        env: job.variables,
        output: output_io,
        error: output_io,
        chdir: context,
      )

      start = Time.local
      status = process.wait
      duration = Time.local - start

      Werk::Model::JobResult.new(
        name: name,
        exit_code: status.exit_code,
        output: buffer_io.to_s,
        duration: duration
      )
    end
  end
end
