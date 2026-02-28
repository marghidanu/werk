module ShellCheck
  class Error < Exception; end

  class Scanner
    # Maps interpreter names to shellcheck-supported dialects.
    # shellcheck supports: sh, bash, dash, ksh
    DIALECTS = {
      "sh" => "sh", "bash" => "bash", "dash" => "dash", "ksh" => "ksh",
      "ash" => "sh", "busybox" => "sh",
    }

    getter path : String

    def initialize(path : String? = nil)
      resolved = path || Process.find_executable("shellcheck")
      raise Error.new("shellcheck not found in PATH") unless resolved

      @path = resolved
    end

    def self.shell_name(interpreter : String) : String?
      name = interpreter.split.last.split("/").last
      DIALECTS[name]?
    end

    def scan(script : String, shell : String) : Array(Finding)
      output = IO::Memory.new
      Process.run(@path, ["-f", "json1", "-s", shell, "-"],
        input: IO::Memory.new(script),
        output: output,
        error: Process::Redirect::Close,
      )

      json = output.to_s
      return [] of Finding if json.empty?

      Array(Finding).from_json(json, root: "comments")
    end
  end
end
