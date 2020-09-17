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
      unless File.exists?(flags.config)
        raise "Configuration file missing!"
      end

      begin
        content = File.read(flags.config)
        if content.empty?
          raise "Configuration file is empty!"
        end

        config = Werk::Model::Config.from_yaml(content)

        target = arguments.target || "main"
        Werk::Scheduler.new(config)
          .run(target, flags.context)
      rescue yaml_ex : YAML::ParseException
        raise "Parse error: #{flags.config}:#{yaml_ex.line_number}:#{yaml_ex.column_number}"
      end
    end
  end
end
