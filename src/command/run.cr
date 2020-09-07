require "../model/*"
require "../scheduler"

module Werk::Command
  class Run < Admiral::Command
    define_help description: "Run target"

    define_argument target : String,
      description: ""

    define_flag config : String,
      description: "",
      default: Path.new(Dir.current, "werk.yml").to_s,
      short: c

    define_flag context : String,
      description: "",
      default: Dir.current,
      short: x

    def run
      if !File.exists?(flags.config)
        raise "Configuration file missing!"
      end

      content = File.read(flags.config)
      config = Werk::Model::Config.from_yaml(content)

      target = arguments.target || "main"

      scheduler = Werk::Scheduler.new(config)
      scheduler.run(target, flags.context)
    end
  end
end
