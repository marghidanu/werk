class Werk::Mcp::GetJobTool < MCP::AbstractTool
  @@tool_name = "get_job"
  @@tool_description = "Get details of a specific job by name"
  @@tool_input_schema = {
    "type"       => "object",
    "properties" => {
      "name" => {
        "type"        => "string",
        "description" => "The job name",
      },
    },
    "required" => ["name"],
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    config = Werk::Mcp::Context.config
    name = params["name"]?.try(&.as_s) || raise Werk::Error.new("Missing required parameter: name")

    job = config.jobs[name]? || raise Werk::Error.new("Job '#{name}' not found")

    data = {
      "name"         => name,
      "description"  => job.description,
      "executor"     => job.executor,
      "entrypoint"   => job.entrypoint,
      "dependencies" => job.needs,
      "commands"     => job.commands,
      "can_fail"     => job.can_fail?,
      "silent"       => job.silent?,
    }

    data
  end
end
