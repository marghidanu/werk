require "tallboy"

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

    define_flag report : Bool,
      description: "",
      short: r

    def run
      config = Werk::Model::Config.load_file(flags.config)

      target = arguments.target || "main"
      scheduler = Werk::Scheduler.new(config)
      report = scheduler.run(target, flags.context)

      if flags.report
        table = get_report_table(report)
        puts table
      end
    end

    def get_report_table(report : Werk::Model::Report)
      table = Tallboy.table do
        header do
          cell "Name", align: :center
          cell "Stage", align: :center
          cell "Job status", align: :center
          cell "Exit code", align: :center
          cell "Duration", align: :center
          cell "Executor", align: :center
        end

        report.plan.each_with_index do |stage, index|
          stage.each do |name|
            job = report.jobs[name]

            row border: :bottom do
              cell job.name
              cell (index + 1)
              cell (job.exit_code == 0) ? "OK" : "Failed"
              cell job.exit_code
              cell sprintf("%.3f secs", job.duration)
              cell "Shell"
            end
          end
        end
      end

      table
    end
  end
end
