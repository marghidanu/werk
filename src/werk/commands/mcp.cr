module Werk::Commands::Mcp
  def self.run(args : Array(String))
    config_file = "werk.yml"
    cwd = "."
    readonly = false

    parser = OptionParser.new do |opt|
      opt.banner = "Usage: werk mcp [options]"
      opt.separator ""
      opt.separator "Start MCP server (experimental)"
      opt.separator ""

      opt.on("-c CONFIG", "--config=CONFIG", "Configuration file name (default: werk.yml)") { |v| config_file = v }
      opt.on("-x DIR", "--cwd=DIR", "Working directory (default: .)") { |v| cwd = v }
      opt.on("-r", "--readonly", "Read-only mode (no job execution)") { readonly = true }
      opt.on("-h", "--help", "Show this help") { puts opt; exit 0 }

      opt.invalid_option { |flag| STDERR.puts "Error: Unknown option '#{flag}'"; STDERR.puts opt; exit 1 }
      opt.missing_option { |flag| STDERR.puts "Error: Missing value for '#{flag}'"; STDERR.puts opt; exit 1 }
    end

    parser.parse(args)

    Werk::Mcp::Context.config_path = config_file
    Werk::Mcp::Context.cwd = cwd

    if readonly
      MCP.registered_tools.delete("run_job")
    end

    print_banner(readonly)
    MCP::StdioHandler.start_server
  end

  private def self.print_banner(readonly : Bool)
    STDERR.puts "werk #{Werk::VERSION} — MCP server (experimental)"
    STDERR.puts
    STDERR.puts "Known limitations:"
    STDERR.puts "  - Encrypted dotenv files are not supported (no TTY for password prompts)"
    STDERR.puts "  - Job output is suppressed to preserve the JSON-RPC stream"
    STDERR.puts "  - Secrets in job output are redacted via gitleaks"
    STDERR.puts
    STDERR.puts "Mode: #{readonly ? "read-only" : "full"}"
    STDERR.flush
  end
end
