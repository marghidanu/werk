module Werk
  module Application
    def self.run
      if ARGV.empty?
        print_help
        return
      end

      case ARGV.shift
      when "plan"
        Werk::Commands::Plan.run(ARGV)
      when "run"
        Werk::Commands::Run.run(ARGV)
      when "mcp"
        Werk::Commands::Mcp.run(ARGV)
      when "vault"
        Werk::Commands::Vault.run(ARGV)
      when "--version", "-v"
        puts "werk #{Werk::VERSION}"
      when "--help", "-h"
        print_help
      else
        STDERR.puts "Unknown command. Use --help for usage."
        exit 1
      end
    end

    private def self.print_help
      puts "werk #{Werk::VERSION}"
      puts
      puts "Usage: werk <command> [options]"
      puts
      puts "Commands:"
      puts "  plan     Display execution plan"
      puts "  run      Run a job by name"
      puts "  mcp      Start MCP server"
      puts "  vault    Manage encrypted dotenv files"
      puts
      puts "Use 'werk <command> --help' for more information on a command."
    end
  end

  begin
    Log.setup_from_env(
      default_sources: "werk.*,docr.*",
      log_level_env: "WERK_LOG_LEVEL",
    )

    Werk::Application.run
  rescue ex : Exception
    puts "Error: #{ex.message}"
    exit 1
  end
end
