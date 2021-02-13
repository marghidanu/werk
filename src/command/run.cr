require "tallboy"
require "colorize"
require "docr"

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
      long: "config",
      short: "c"

    define_flag context : String,
      description: "Working directory",
      default: ".",
      long: "context",
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
      long: "report",
      short: "r"

    define_flag clear : Bool,
      description: "Clear terminal",
      long: "clear",
      short: "l"

    define_flag variables : Array(String),
      description: "",
      long: "env",
      short: "e"

    def run
      config = (flags.stdin) ? Werk::Model::Config.load_string(STDIN.gets_to_end) : Werk::Model::Config.load_file(flags.config)

      Werk::Utils::Term.clear_screen if flags.clear

      Signal::INT.trap do
        client = Docr::Client.new
        api = Docr::API.new(client)

        # Retrieveing the existing containers based on a unique label for this execution
        containers = api.containers.list(
          filters: {
            "label": ["com.stuffo.werk.session_id=#{config.session_id}"],
          }
        )

        # Killing remaining containers and waiting for the execution to end
        containers.each do |container|
          Log.debug { "Stopping container #{container.id}" }
          api.containers.kill(container.id, "SIGINT")
          api.containers.wait(container.id)
        end
      rescue ex
        Log.debug { ex.message }
      ensure
        exit(2)
      end

      # Parsing additional variables
      variables = Hash(String, String).new
      flags.variables.each do |item|
        data = item.match(/^(?P<name>[[:alpha:]_][[:alpha:][:digit:]_]*)=(?P<value>.*)$/)
        variables[data["name"]] = data["value"] if data
      end

      scheduler = Werk::Scheduler.new(config)
      report = scheduler.run(
        target: (arguments.target || "main"),
        context: flags.context,
        variables: variables,
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
            next unless report.jobs.has_key?(name)
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
