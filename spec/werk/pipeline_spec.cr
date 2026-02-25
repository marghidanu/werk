require "../spec_helper"

describe Werk::Pipeline do
  it "should run a simple local job" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo hello werk
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", Hash(String, String).new)

    result.target.should eq "main"
    result.find_job("main").exit_code.should eq 0
    result.find_job("main").output.should contain "hello werk"
  end

  it "should run jobs with dependencies in order" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - setup
          commands:
            - echo main done
        setup:
          executor: local
          commands:
            - echo setup done
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", Hash(String, String).new)

    result.find_job("setup").exit_code.should eq 0
    result.find_job("main").exit_code.should eq 0
    result.find_job("setup").output.should contain "setup done"
    result.find_job("main").output.should contain "main done"
  end

  it "should stop pipeline on job failure" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - failing
          commands:
            - echo should not run
        failing:
          executor: local
          commands:
            - exit 1
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", Hash(String, String).new)

    result.find_job("failing").exit_code.should eq 1
    result.has_job?("main").should be_false
  end

  it "should continue pipeline when can_fail is set" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - flaky
          commands:
            - echo main ran
        flaky:
          executor: local
          can_fail: true
          commands:
            - exit 1
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", Hash(String, String).new)

    result.find_job("flaky").exit_code.should eq 1
    result.find_job("main").exit_code.should eq 0
  end

  it "should stop pipeline when one parallel job fails in a stage" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - passing
            - failing
          commands:
            - echo should not run
        passing:
          executor: local
          commands:
            - sleep 0.2 && echo ok
        failing:
          executor: local
          commands:
            - exit 1
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", Hash(String, String).new)

    result.find_job("failing").exit_code.should eq 1
    result.find_job("passing").exit_code.should eq 0
    result.has_job?("main").should be_false
  end

  it "should handle docker job failure with nonexistent image" do
    pending!("Docker not available") unless Docr::Client.available?

    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: docker
          image: "nonexistent-image-that-does-not-exist:99.99.99"
          commands:
            - echo hello
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", Hash(String, String).new)

    result.find_job("main").exit_code.should eq 255
  end

  it "should not mutate job config variables between runs" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          variables:
            MY_VAR: original
          commands:
            - echo $MY_VAR
    ))

    # Check the original config state
    config.jobs["main"].variables.size.should eq 1
    config.jobs["main"].variables["MY_VAR"].should eq "original"

    # First run
    pipeline = Werk::Pipeline.new(config)
    pipeline.run("main", ".", Hash(String, String).new)

    # After run, config should not have WERK_* variables injected
    config.jobs["main"].variables.has_key?("WERK_SESSION_ID").should be_false
    config.jobs["main"].variables["MY_VAR"].should eq "original"
  end

  it "should pass variables to jobs" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo $MY_VAR
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", {"MY_VAR" => "hello from var"})

    result.find_job("main").exit_code.should eq 0
    result.find_job("main").output.should contain "hello from var"
  end

  it "should inject WERK_* variables into jobs" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo $WERK_JOB_NAME $WERK_SESSION_TARGET
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", Hash(String, String).new)

    result.find_job("main").exit_code.should eq 0
    result.find_job("main").output.should contain "main main"
  end

  it "should pass job-level variables to jobs" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          variables:
            JOB_VAR: from_job
          commands:
            - echo $JOB_VAR
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", Hash(String, String).new)

    result.find_job("main").exit_code.should eq 0
    result.find_job("main").output.should contain "from_job"
  end

  it "should pass global config variables to jobs" do
    config = Werk::Config.load_string(%(
      version: 1.0
      variables:
        GLOBAL_VAR: from_config
      jobs:
        main:
          executor: local
          commands:
            - echo $GLOBAL_VAR
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", Hash(String, String).new)

    result.find_job("main").exit_code.should eq 0
    result.find_job("main").output.should contain "from_config"
  end

  it "should let run variables override job variables" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          variables:
            MY_VAR: from_job
          commands:
            - echo $MY_VAR
    ))

    pipeline = Werk::Pipeline.new(config)
    result = pipeline.run("main", ".", {"MY_VAR" => "from_run"})

    result.find_job("main").exit_code.should eq 0
    result.find_job("main").output.should contain "from_run"
  end

  it "should report terminated? as false by default" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo hello
    ))

    pipeline = Werk::Pipeline.new(config)
    pipeline.terminated?.should be_false
  end

  it "should report terminated? as true after terminate" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo hello
    ))

    pipeline = Werk::Pipeline.new(config)
    pipeline.terminate
    pipeline.terminated?.should be_true
  end

  it "should terminate a running local job" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - sleep 60
    ))

    pipeline = Werk::Pipeline.new(config)

    result_channel = Channel(Werk::PipelineResult).new
    spawn do
      result = pipeline.run("main", ".", Hash(String, String).new)
      result_channel.send(result)
    end

    # Give the job time to start
    sleep 0.5.seconds

    pipeline.terminate

    result = result_channel.receive
    pipeline.terminated?.should be_true
    result.find_job("main").exit_code.should_not eq 0
  end

  it "should not run subsequent stages after terminate" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - slow
          commands:
            - echo should not run
        slow:
          executor: local
          commands:
            - sleep 60
    ))

    pipeline = Werk::Pipeline.new(config)

    result_channel = Channel(Werk::PipelineResult).new
    spawn do
      result = pipeline.run("main", ".", Hash(String, String).new)
      result_channel.send(result)
    end

    sleep 0.5.seconds

    pipeline.terminate

    result = result_channel.receive
    result.has_job?("slow").should be_true
    result.has_job?("main").should be_false
  end
end
