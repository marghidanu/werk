module Werk::Commands::Run
  Log = ::Log.for(self)

  def self.run(args : Array(String))
    config_file = "werk.yml"
    cwd = Dir.current
    max_jobs = 0
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
      opt.on("-x DIR", "--cwd=DIR", "Working directory (default: .)") { |v| cwd = Path[v].expand.to_s }
      opt.on("-j JOBS", "--jobs=JOBS", "Max parallel jobs (default: 0 = auto)") { |v| max_jobs = v.to_i32 }
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
    variables = Werk::Variables.parse(env_vars_raw)
    config.max_jobs = max_jobs if max_jobs > 0

    pipeline = Werk::Pipeline.new(config)
    report = pipeline.run(
      target: target,
      cwd: cwd,
      variables: variables,
      yes: yes,
    )

    puts report.to_table if show_report
    exit 1 if pipeline.terminated?
  end
end
