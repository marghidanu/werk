module Werk::Commands
  module Mcp
    def self.run(args : Array(String))
      config_file = "werk.yml"
      cwd = "."
      readonly = false

      parser = OptionParser.new do |opt|
        opt.banner = "Usage: werk mcp [options]"
        opt.separator ""
        opt.separator "Start MCP server"
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

      MCP.registered_tools.delete("run_job") if readonly

      # Suppress job output to STDOUT — it would corrupt the JSON-RPC stream
      Werk::Utils::PrefixIO.enabled = false

      STDERR.puts "MCP server started. Available tools: #{MCP.registered_tools.keys.join(", ")}"
      STDERR.flush

      # NOTE: Custom stdio loop instead of MCP::StdioHandler.start_server because
      # start_server prints a plain-text banner to STDOUT, which corrupts
      # the JSON-RPC stream. See: https://github.com/ralsina/mcp/issues/1
      while !STDIN.closed?
        line = STDIN.gets
        break unless line

        line = line.strip
        next if line.empty?

        response = MCP::StdioHandler.handle_request(line)
        STDOUT.puts response
        STDOUT.flush
      end
    end
  end
end
