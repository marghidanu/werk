module Werk
  class Application < Admiral::Command
    define_version Werk::VERSION
    define_help description: "Werk"

    register_sub_command plan : Werk::Commands::Plan,
      description: "Display execution plan"

    register_sub_command run : Werk::Commands::Run,
      description: "Run a job by name"

    register_sub_command mcp : Werk::Commands::Mcp,
      description: "Start MCP server"

    def run
      puts help
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
