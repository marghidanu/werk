require "log"
require "../model/*"

module Werk::Command
  class Init < Admiral::Command
    define_help description: "Create empty werk config file"

    define_flag config : String,
      description: "",
      default: Path.new(Dir.current, "werk.yml").to_s,
      short: c

    def run
      # Check if configuration file already exists
      if File.exists?(flags.config)
        raise "Environment already initialized!"
      end

      default_job = Werk::Model::Job.new(
        description: "Default job",
        commands: [
          "echo \"Hello world!\""
        ]
      )

      config = Werk::Model::Config.new(
        description: "Lorem ipsum dolor sic amet ...",
        jobs: {
          "default" => default_job,
        }
      )

      # Save configuration file to disk
      Log.info { "Saving configuration to #{flags.config}" }
      File.write(flags.config, config.to_yaml)
    end
  end
end
