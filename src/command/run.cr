require "../model/*"
require "../scheduler"

module Werk::Command
  class Run < Admiral::Command
    define_help description: "Run target"

    define_argument target : String,
      description: "",
      default: "main"

    define_flag config : String,
      description: "",
      default: Path.new(Dir.current, "werk.yml").to_s,
      short: c

    define_flag context : String,
      description: "",
      default: Dir.current,
      short: x

    def run
      config = Werk::Model::Config.load_file(flags.config)

      target = arguments.target || "main"
      Werk::Scheduler.new(config)
        .run(target, flags.context)
    end
  end
end
