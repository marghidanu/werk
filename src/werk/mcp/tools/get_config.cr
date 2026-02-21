class Werk::Mcp::GetConfigTool < MCP::AbstractTool
  @@tool_name = "get_config"
  @@tool_description = "Get werkfile configuration summary"
  @@tool_input_schema = {
    "type"       => "object",
    "properties" => {} of String => String,
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    config = Werk::Mcp::Context.config

    data = {
      "version"     => config.version,
      "description" => config.description,
      "max_jobs"    => config.max_jobs,
      "job_count"   => config.jobs.size,
      "job_names"   => config.jobs.keys,
      "dotenv"      => config.dotenv.to_a,
    }

    {"content" => [{"type" => "text", "text" => data.to_json}]}
  end
end
