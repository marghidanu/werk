module Gitleaks
  class Scanner
    Log = ::Log.for(self)

    getter path : String

    def initialize(path : String? = nil)
      resolved = path || Process.find_executable("gitleaks")
      raise "gitleaks not found in PATH" unless resolved
      raise "gitleaks not found at #{resolved}" unless File.exists?(resolved)

      @path = resolved
    end

    def version : String
      output = IO::Memory.new
      Process.run(@path, ["version"], output: output, error: Process::Redirect::Close)
      output.to_s.strip
    end

    def scan(text : String) : Array(Result)
      return [] of Result if text.empty?

      config_file = File.tempfile("gitleaks", ".toml") do |file|
        file.print(BUILTIN_RULES)
      end

      begin
        args = ["stdin", "--report-format", "json", "--report-path", "-", "--no-banner", "-c", config_file.path]

        output = IO::Memory.new
        Process.run(
          @path,
          args,
          input: IO::Memory.new(text),
          output: output,
          error: Process::Redirect::Close,
        )

        report = output.to_s
        return [] of Result if report.empty? || report.strip == "[]"

        results = Array(Result).from_json(report)
        Log.debug { "Found #{results.size} secret(s)" }

        results
      ensure
        config_file.delete
      end
    end
  end
end
