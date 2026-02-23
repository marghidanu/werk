module Werk::Commands
  module Run
    Log = ::Log.for(self)

    def self.run(args : Array(String))
      config_file = "werk.yml"
      context = "."
      max_jobs = 0_u32
      from_stdin = false
      show_report = false
      env_vars_raw = [] of String
      yes = false

      parser = OptionParser.new do |opt|
        opt.banner = "Usage: werk run [target] [options]"
        opt.separator ""
        opt.separator "Run a job by name"
        opt.separator ""

        opt.on("-c CONFIG", "--config=CONFIG", "Configuration file name (default: werk.yml)") { |v| config_file = v }
        opt.on("-x DIR", "--context=DIR", "Working directory (default: .)") { |v| context = v }
        opt.on("-j JOBS", "--jobs=JOBS", "Max parallel jobs (default: 0 = auto)") { |v| max_jobs = v.to_u32 }
        opt.on("--stdin", "Read configuration from STDIN") { from_stdin = true }
        opt.on("-r", "--report", "Display execution report") { show_report = true }
        opt.on("-e VAR", "--env=VAR", "Export additional environment variables (repeatable)") { |v| env_vars_raw << v }
        opt.on("-y", "--yes", "Set WERK_YES to true") { yes = true }
        opt.on("-h", "--help", "Show this help") { puts opt; exit 0 }

        opt.invalid_option { |flag| STDERR.puts "Error: Unknown option '#{flag}'"; STDERR.puts opt; exit 1 }
        opt.missing_option { |flag| STDERR.puts "Error: Missing value for '#{flag}'"; STDERR.puts opt; exit 1 }
      end

      parser.parse(args)
      target = args.first? || "main"

      config = from_stdin ? Werk::Config.load_string(STDIN.gets_to_end) : Werk::Config.load_file(config_file)

      # Parsing additional variables
      variables = Hash(String, String).new
      env_vars_raw.each do |item|
        data = item.match(/^(?P<name>[[:alpha:]_][[:alpha:][:digit:]_]*)=(?P<value>.*)$/)
        variables[data["name"]] = data["value"] if data
      end

      # Override max_jobs if a different value is specified as a flag
      config.max_jobs = max_jobs if max_jobs > 0

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
        target: target,
        cwd: context,
        variables: variables,
        yes: yes,
      )

      display_report(report) if show_report

      exit 1 if pipeline.terminated?
    end

    def self.display_report(result)
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
