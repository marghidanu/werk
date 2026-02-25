class Werk::Mcp::GetPlanTool < MCP::AbstractTool
  @@tool_name = "get_plan"
  @@tool_description = "Get the execution plan (stages) for a target"
  @@tool_input_schema = {
    "type"       => "object",
    "properties" => {
      "target" => {
        "type"        => "string",
        "description" => "The target job name (default: main)",
      },
    },
  }.to_json

  def invoke(params : Hash(String, JSON::Any), env : HTTP::Server::Context? = nil)
    config = Werk::Mcp::Context.config
    target = params["target"]?.try(&.as_s) || "main"

    pipeline = Werk::Pipeline.new(config)
    plan = pipeline.scheduler.get_plan(target)

    stages = plan.map_with_index do |stage, idx|
      {"stage" => idx, "jobs" => stage.to_a}
    end

    {"target" => target, "stages" => stages}
  end
end
