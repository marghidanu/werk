require "log"
require "tallboy"
require "colorize"
require "docr"

require "../model/*"
require "../scheduler"

module Werk
  class Command::Run < Admiral::Command
    Log = ::Log.for(self)

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

    define_flag max_jobs : UInt32,
      description: "Max parallel jobs",
      default: 0_u32,
      long: "jobs",
      short: "j"

    define_flag stdin : Bool,
      description: "Read configuration from STDIN",
      long: "stdin"

    define_flag report : Bool,
      description: "Display execution report",
      long: "report",
      short: "r"

    define_flag variables : Array(String),
      description: "",
      long: "env",
      short: "e"

    def run
      config = (flags.stdin) ? Werk::Model::Config.load_string(STDIN.gets_to_end) : Werk::Model::Config.load_file(flags.config)

      # Parsing additional variables
      variables = Hash(String, String).new
      flags.variables.each do |item|
        data = item.match(/^(?P<name>[[:alpha:]_][[:alpha:][:digit:]_]*)=(?P<value>.*)$/)
        variables[data["name"]] = data["value"] if data
      end

      # Override max_jobs if a different value is specified ar an flag
      config.max_jobs = flags.max_jobs if flags.max_jobs > 0

      # Creating the scheduler ...
      scheduler = Werk::Scheduler.new(config)

      Signal::INT.trap {
        Log.debug { "Captured SIGINT!" }
        cleanup(scheduler.session_id)
      }

      Signal::TERM.trap {
        Log.debug { "Captured SIGTERM!" }
        cleanup(scheduler.session_id)
      }

      # ... and running the job
      report = scheduler.run(
        target: (arguments.target || "main"),
        context: flags.context,
        variables: variables,
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

    def cleanup(session_id : UUID)
      # TODO: This logic needs to sit somewhere else ...
      client = Docr::Client.new
      api = Docr::API.new(client)

      # Retrieveing the existing containers based on a unique label for this execution
      Log.debug { "Retrieve a list of running containers" }
      containers = api.containers.list(
        filters: {
          "label": ["com.stuffo.werk.session_id=#{session_id}"],
        }
      )

      Log.debug { "Killing #{containers.size} containers..." }

      # Killing remaining containers and waiting for the execution to end
      containers.each do |container|
        Log.debug { "Stopping container '#{container.id}'" }
        api.containers.kill(container.id, "SIGINT")
        api.containers.wait(container.id)
      end
    rescue ex
      Log.debug { ex.message }
    ensure
      exit(1)
    end
  end
end
