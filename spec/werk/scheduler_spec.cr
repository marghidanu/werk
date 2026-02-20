require "../spec_helper"

describe Werk::Scheduler do
  it "should generate an execution plan for a single job" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo hello
    ))

    scheduler = Werk::Scheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 1
    plan[0].should eq Set{"main"}
  end

  it "should generate a plan with dependencies" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - build
        build:
          executor: local
          needs:
            - test
        test:
          executor: local
          commands:
            - echo testing
    ))

    scheduler = Werk::Scheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 3
    plan[0].should eq Set{"test"}
    plan[1].should eq Set{"build"}
    plan[2].should eq Set{"main"}
  end

  it "should generate parallel stages for independent dependencies" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - lint
            - test
        lint:
          executor: local
          commands:
            - echo lint
        test:
          executor: local
          commands:
            - echo test
    ))

    scheduler = Werk::Scheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 2
    plan[0].should eq Set{"lint", "test"}
    plan[1].should eq Set{"main"}
  end

  it "should raise for undefined job" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - missing
    ))

    scheduler = Werk::Scheduler.new(config)

    expect_raises(Exception, "Job 'missing' is not defined!") do
      scheduler.get_plan("main")
    end
  end

  it "should run a simple local job" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo hello werk
    ))

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", Hash(String, String).new)

    report.target.should eq "main"
    report.jobs["main"].exit_code.should eq 0
    report.jobs["main"].output.should contain "hello werk"
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

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", Hash(String, String).new)

    report.jobs["setup"].exit_code.should eq 0
    report.jobs["main"].exit_code.should eq 0
    report.jobs["setup"].output.should contain "setup done"
    report.jobs["main"].output.should contain "main done"
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

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", Hash(String, String).new)

    report.jobs["failing"].exit_code.should eq 1
    report.jobs.has_key?("main").should be_false
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

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", Hash(String, String).new)

    report.jobs["flaky"].exit_code.should eq 1
    report.jobs["main"].exit_code.should eq 0
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

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", Hash(String, String).new)

    report.jobs["failing"].exit_code.should eq 1
    report.jobs["passing"].exit_code.should eq 0
    report.jobs.has_key?("main").should be_false
  end

  it "should handle docker job failure with nonexistent image" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: docker
          image: "nonexistent-image-that-does-not-exist:99.99.99"
          commands:
            - echo hello
    ))

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", Hash(String, String).new)

    report.jobs["main"].exit_code.should eq 255
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
    scheduler = Werk::Scheduler.new(config)
    scheduler.run("main", ".", Hash(String, String).new)

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

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", {"MY_VAR" => "hello from var"})

    report.jobs["main"].exit_code.should eq 0
    report.jobs["main"].output.should contain "hello from var"
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

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", Hash(String, String).new)

    report.jobs["main"].exit_code.should eq 0
    report.jobs["main"].output.should contain "main main"
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

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", Hash(String, String).new)

    report.jobs["main"].exit_code.should eq 0
    report.jobs["main"].output.should contain "from_job"
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

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", Hash(String, String).new)

    report.jobs["main"].exit_code.should eq 0
    report.jobs["main"].output.should contain "from_config"
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

    scheduler = Werk::Scheduler.new(config)
    report = scheduler.run("main", ".", {"MY_VAR" => "from_run"})

    report.jobs["main"].exit_code.should eq 0
    report.jobs["main"].output.should contain "from_run"
  end
end
