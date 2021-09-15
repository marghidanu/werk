require "admiral"
require "log"

require "./command/*"

module Werk
  VERSION = "0.6.0"

  class Application < Admiral::Command
    define_version Werk::VERSION
    define_help description: "Werk"

    register_sub_command plan : Werk::Command::Plan,
      description: "Display execution plan"

    register_sub_command run : Werk::Command::Run,
      description: "Run a job by name"

    def run
      puts help
    end
  end
end

begin
  Log.setup_from_env(
    default_sources: "werk.*",
    log_level_env: "WERK_LOG_LEVEL",
  )

  Werk::Application.run
rescue ex : Exception
  puts "Error: #{ex.message}"
  exit(1)
end
