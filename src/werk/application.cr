require "admiral"

require "./commands/*"

module Werk
  class Application < Admiral::Command
    define_version Werk::VERSION
    define_help description: "Werk"

    register_sub_command plan : Werk::Commands::Plan,
      description: "Display execution plan"

    register_sub_command run : Werk::Commands::Run,
      description: "Run a job by name"

    def run
      puts help
    end
  end
end
