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
      "variables" => {
        "type"        => "object",
        "description" => "Environment variables to pass to the job (key-value pairs)",
      },
      "yes" => {
        "type"        => "boolean",
        "description" => "Set WERK_YES to true (auto-confirm prompts)",
      },
      "max_jobs" => {
        "type"        => "integer",
        "description" => "Max parallel jobs (0 = auto, based on CPU count)",
      },
    },
    "required" => ["target"],
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    config = Werk::Mcp::Context.config
    target = params["target"]?.try(&.as_s) || raise Werk::Error.new("Missing required parameter: target")
    yes = params["yes"]?.try(&.as_bool?) || false
    max_jobs = params["max_jobs"]?.try(&.as_i?) || 0
    variables = (params["variables"]?.try(&.as_h?) || {} of String => JSON::Any).transform_values(&.raw.to_s)
    config.max_jobs = max_jobs if max_jobs > 0

    Werk::Utils::PrefixIO.enabled = false
    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run(
      target: target,
      cwd: Werk::Mcp::Context.cwd,
      variables: variables,
      yes: yes,
    )

    {"result" => result}
  ensure
    Werk::Utils::PrefixIO.enabled = true
  end
end
