require "admiral"
require "log"

require "./command/*"

module Werk
  VERSION = "0.5.3"

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
  Log.setup_from_env

  Werk::Application.run
rescue ex : Exception
  Log.error { ex.message }
  exit(1)
end
