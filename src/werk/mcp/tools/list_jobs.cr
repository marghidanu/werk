class Werk::Mcp::ListJobsTool < MCP::AbstractTool
  @@tool_name = "list_jobs"
  @@tool_description = "List all jobs defined in the werkfile"
  @@tool_input_schema = {
    "type"       => "object",
    "properties" => {} of String => String,
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    config = Werk::Mcp::Context.config

    jobs = config.jobs.map do |name, job|
      {
        "name"         => name,
        "description"  => job.description,
        "executor"     => job.executor,
        "dependencies" => job.needs,
      }
    end

    {"content" => [{"type" => "text", "text" => {"jobs" => jobs}.to_json}]}
  end
end
