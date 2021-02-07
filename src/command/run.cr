require "tallboy"
require "colorize"

require "../model/*"
require "../scheduler"
require "../utils/term"

module Werk::Command
  class Run < Admiral::Command
    define_help description: "Run target"

    define_argument target : String,
      description: "Target job name",
      default: "main"

    define_flag config : String,
      description: "Configuration file name",
      default: "werk.yml",
      short: "c"

    define_flag context : String,
      description: "Working directory",
      default: ".",
      short: "x"

    define_flag max_parallel_jobs : Int32,
      description: "Max parallel jobs",
      default: 32,
      long: "jobs",
      short: "j"

    define_flag stdin : Bool,
      description: "Read configuration from STDIN",
      long: "stdin"

    define_flag report : Bool,
      description: "Display execution report",
      short: "r"

    define_flag clear : Bool,
      description: "Clear terminal",
      short: "l"

    def run
      config = (flags.stdin) ? Werk::Model::Config.load_string(STDIN.gets_to_end) : Werk::Model::Config.load_file(flags.config)

      Werk::Utils::Term.clear_screen if flags.clear

      scheduler = Werk::Scheduler.new(config)
      report = scheduler.run(
        target: (arguments.target || "main"),
        context: flags.context,
        max_parallel_jobs: flags.max_parallel_jobs
      )

      display_report(report) if flags.report
    end

    def display_report(report)
      table = Tallboy.table do
        header do
          cell "Name", align: :center
          cell "Stage", align: :center
          cell "Status", align: :center
          cell "Exit code", align: :center
          cell "Duration", align: :center
          cell "Executor", align: :center
        end

        report.plan.each_with_index do |stage, index|
          stage.each do |name|
            job = report.jobs[name]

            row border: :bottom do
              cell job.name
              cell index
              cell (job.exit_code == 0) ? "OK".colorize(:green) : "Failed".colorize(:red), align: :center
              cell job.exit_code
              cell sprintf("%.3f secs", job.duration)
              cell job.executor
            end
          end
        end
      end

      puts table
    end
  end
end
