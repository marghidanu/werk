require "admiral"
require "tallboy"
require "colorize"

require "../config"
require "../scheduler"

module Werk::Commands
  class Plan < Admiral::Command
    define_help description: "List jobs information"

    define_argument target : String,
      description: "Job name",
      default: "main"

    define_flag config : String,
      description: "Configuration file name",
      default: "werk.yml",
      short: "c"

    define_flag stdin : Bool,
      description: "Read configuration from STDIN",
      long: "stdin"

    def run
      config = flags.stdin ? Werk::Config.load_string(STDIN.gets_to_end) : Werk::Config.load_file(flags.config)

      target = arguments.target || "main"
      plan = Werk::Scheduler.new(config).get_plan(target)

      table = Tallboy.table do
        plan.each_with_index do |stage, index|
          header "Stage #{index}".colorize(:yellow), align: :center
          header do
            cell "Name", align: :center
            cell "Description", align: :center
            cell "Can fail?", align: :center
          end

          stage.each do |name|
            job = config.jobs[name]

            row border: :bottom do
              cell (name == target) ? name.colorize(:blue) : name, align: :center
              cell job.description.empty? ? "[No description]" : job.description
              cell job.can_fail? ? "Yes".colorize(:red) : "No".colorize(:green), align: :center
            end
          end
        end
      end

      puts table
    end
  end
end
