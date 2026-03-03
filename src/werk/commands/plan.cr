module Werk::Commands::Plan
  def self.run(args : Array(String))
    config_file = "werk.yml"
    from_stdin = false

    parser = OptionParser.new do |opt|
      opt.banner = "Usage: werk plan [target] [options]"
      opt.separator ""
      opt.separator "Display execution plan"
      opt.separator ""

      opt.on("-c CONFIG", "--config=CONFIG", "Configuration file name (default: werk.yml)") { |v| config_file = v }
      opt.on("--stdin", "Read configuration from STDIN") { from_stdin = true }
      opt.on("-h", "--help", "Show this help") { puts opt; exit 0 }

      opt.invalid_option { |flag| STDERR.puts "Error: Unknown option '#{flag}'"; STDERR.puts opt; exit 1 }
      opt.missing_option { |flag| STDERR.puts "Error: Missing value for '#{flag}'"; STDERR.puts opt; exit 1 }
    end

    parser.parse(args)
    target = args.first? || "main"

    config = from_stdin ? Werk::Config.load_string(STDIN.gets_to_end) : Werk::Config.load_file(config_file)
    plan = Werk::Pipeline.new(config).scheduler.get_plan(target)

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
