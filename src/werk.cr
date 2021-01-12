require "admiral"

require "./version"
require "./command/*"

module Werk
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
  Werk::Application.run
rescue ex : Exception
  puts(ex.message)
  exit(1)
end
