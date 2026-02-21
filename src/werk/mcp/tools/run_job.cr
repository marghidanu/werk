class Werk::Mcp::RunJobTool < MCP::AbstractTool
  @@tool_name = "run_job"
  @@tool_description = "Execute a job target and return the result (full mode only)"
  @@tool_input_schema = {
    "type"       => "object",
    "properties" => {
      "target" => {
        "type"        => "string",
        "description" => "The target job name to execute",
      },
    },
    "required" => ["target"],
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    config = Werk::Mcp::Context.config
    target = params["target"]?.try(&.as_s) || raise "Missing required parameter: target"

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run(
      target: target,
      cwd: Werk::Mcp::Context.cwd,
      variables: Hash(String, String).new,
    )

    {"content" => [{"type" => "text", "text" => result.to_json}]}
  end
end
