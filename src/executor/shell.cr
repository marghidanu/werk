module Werk::Executor
  class Shell < Werk::Executor::Base
    def run(name : String, job : Werk::Model::Job, context : String)
      content = [
        "#!/bin/sh",
        "set -o errexit",
        "set -o nounset",
      ]
      content.concat(job.commands)

      script = File.tempfile
      File.write(script.path, content.join("\n"))
      File.chmod(script.path, 0o755)

      output = IO::Memory.new
      process = Process.new(". #{script.path}",
        shell: true,
        env: job.variables,
        output: output,
        error: output,
        chdir: context,
      )

      start = Time.local
      status = process.wait
      duration = Time.local - start

      Werk::Model::JobResult.new(
        name: name,
        exit_code: status.exit_code,
        output: output.to_s,
        duration: duration
      )
    end
  end
end
