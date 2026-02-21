module Werk::Commands
  class Mcp < Admiral::Command
    define_help description: "Start MCP server"

    # ameba:disable Lint/UselessAssign
    define_flag config : String,
      description: "Configuration file name",
      default: "werk.yml",
      short: "c"

    # ameba:disable Lint/UselessAssign
    define_flag cwd : String,
      description: "Working directory",
      default: ".",
      short: "x"

    # ameba:disable Lint/UselessAssign
    define_flag readonly : Bool,
      description: "Read-only mode (no job execution)",
      default: false,
      short: "r"

    def run
      Werk::Mcp::Context.config_path = flags.config
      Werk::Mcp::Context.cwd = flags.cwd

      MCP.registered_tools.delete("run_job") if flags.readonly

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
