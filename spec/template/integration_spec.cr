require "../spec_helper"

describe "Template integration" do
  describe "Variable expansion" do
    it "should expand variables referencing other variables" do
      vars = Template::Interpolation.new.expand({
        "REGISTRY" => "ghcr.io",
        "IMAGE"    => "${REGISTRY}/myapp",
      }).variables

      vars["IMAGE"].should eq "ghcr.io/myapp"
    end

    it "should expand chained references" do
      vars = Template::Interpolation.new.expand({
        "A" => "hello",
        "B" => "${A} world",
        "C" => "${B}!",
      }).variables

      vars["C"].should eq "hello world!"
    end

    it "should leave undefined references as-is" do
      vars = Template::Interpolation.new.expand({
        "A" => "${UNDEFINED}",
      }).variables

      vars["A"].should eq "${UNDEFINED}"
    end

    it "should raise on circular references" do
      expect_raises(Craph::CycleError) do
        Template::Interpolation.new.expand({
          "A" => "${B}",
          "B" => "${A}",
        })
      end
    end

    it "should raise on self-reference" do
      expect_raises(Craph::CycleError) do
        Template::Interpolation.new.expand({
          "A" => "${A}",
        })
      end
    end

    it "should raise when a cycle exists even if other variables are acyclic" do
      expect_raises(Craph::CycleError) do
        Template::Interpolation.new.expand({
          "A"     => "base",
          "B"     => "${A}/path",
          "LOOP"  => "${CYCLE}",
          "CYCLE" => "${LOOP}",
        })
      end
    end

    it "should resolve diamond dependencies" do
      vars = Template::Interpolation.new.expand({
        "A" => "x",
        "B" => "${A}1",
        "C" => "${A}2",
        "D" => "${B}-${C}",
      }).variables

      vars["D"].should eq "x1-x2"
    end

    it "should not expand variables with no references" do
      vars = Template::Interpolation.new.expand({
        "A" => "plain",
        "B" => "also plain",
      }).variables

      vars["A"].should eq "plain"
      vars["B"].should eq "also plain"
    end
  end

  describe "Pipeline integration" do
    it "should expand variables in the pipeline" do
      config = Werk::Config.load_string(%(
        version: 1.0
        variables:
          GREETING: hello from template
        jobs:
          main:
            executor: local
            commands:
              - echo ${GREETING}
      ))

      pipeline = Werk::Pipeline.new(config)
      result = pipeline.run("main", ".", Hash(String, String).new)

      result.find_job("main").exit_code.should eq 0
      result.find_job("main").output.should contain "hello from template"
    end

    it "should expand variables referencing other variables in the pipeline" do
      config = Werk::Config.load_string(%(
        version: 1.0
        variables:
          BASE: ghcr.io
          IMAGE: ${BASE}/myapp
        jobs:
          main:
            executor: local
            commands:
              - echo ${IMAGE}
      ))

      pipeline = Werk::Pipeline.new(config)
      result = pipeline.run("main", ".", Hash(String, String).new)

      result.find_job("main").exit_code.should eq 0
      result.find_job("main").output.should contain "ghcr.io/myapp"
    end

    it "should not mutate job config between pipeline runs" do
      config = Werk::Config.load_string(%(
        version: 1.0
        jobs:
          main:
            executor: local
            description: "Run ${WERK_JOB_NAME}"
            commands:
              - echo done
      ))

      original_description = config.jobs["main"].description

      pipeline = Werk::Pipeline.new(config)
      pipeline.run("main", ".", Hash(String, String).new)

      config.jobs["main"].description.should eq original_description
    end

    it "should interpolate CLI variables in config fields" do
      config = Werk::Config.load_string(%(
        version: 1.0
        jobs:
          main:
            executor: local
            commands:
              - echo ${RUNTIME_VAR}
      ))

      pipeline = Werk::Pipeline.new(config)
      result = pipeline.run("main", ".", {"RUNTIME_VAR" => "from_cli"})

      result.find_job("main").exit_code.should eq 0
      result.find_job("main").output.should contain "from_cli"
    end
  end
end
