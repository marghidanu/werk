module Werk::Commands
  class Run < Admiral::Command
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
      description: "Export additional environment variables",
      long: "env",
      short: "e"

    define_flag yes : Bool,
      description: "Set flag for WERK_YES to true",
      long: "yes",
      short: "y",
      default: false

    def run
      config = flags.stdin ? Werk::Config.load_string(STDIN.gets_to_end) : Werk::Config.load_file(flags.config)

      # Parsing additional variables
      variables = Hash(String, String).new
      flags.variables.each do |item|
        data = item.match(/^(?P<name>[[:alpha:]_][[:alpha:][:digit:]_]*)=(?P<value>.*)$/)
        variables[data["name"]] = data["value"] if data
      end

      # Override max_jobs if a different value is specified as a flag
      config.max_jobs = flags.max_jobs if flags.max_jobs > 0

      # Creating the pipeline ...
      pipeline = Werk::Pipeline.new(config)

      [Signal::INT, Signal::TERM].each do |signal|
        signal.trap {
          Log.debug { "Captured #{signal}!" }
          pipeline.terminate
        }
      end

      # ... and running the job
      report = pipeline.run(
        target: (arguments.target || "main"),
        cwd: flags.context,
        variables: variables,
        yes: flags.yes,
      )

      display_report(report) if flags.report

      exit 1 if pipeline.terminated?
    end

    def display_report(result)
      table = Tallboy.table do
        header do
          cell "Name", align: :center
          cell "Stage", align: :center
          cell "Status", align: :center
          cell "Exit code", align: :center
          cell "Duration", align: :center
          cell "Executor", align: :center
        end

        result.jobs.each do |job|
          row border: :bottom do
            cell job.name
            cell job.stage_id
            cell job.success? ? "OK".colorize(:green) : "Failed".colorize(:red), align: :center
            cell job.exit_code
            cell sprintf("%.3f secs", job.duration)
            cell job.executor
          end
        end
      end

      puts table
    end
  end
end
