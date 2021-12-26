require "log"

require "./application"

begin
  Log.setup_from_env(
    default_sources: "werk.*",
    log_level_env: "WERK_LOG_LEVEL",
  )

  Werk::Application.run
rescue ex : Exception
  puts "Error: #{ex.message}"
  exit(1)
end
