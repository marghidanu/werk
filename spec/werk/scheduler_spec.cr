require "../spec_helper"

describe Werk::ParallelScheduler do
  it "should generate an execution plan for a single job" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo hello
    ))

    scheduler = Werk::ParallelScheduler.new(config)
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

    scheduler = Werk::ParallelScheduler.new(config)
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

    scheduler = Werk::ParallelScheduler.new(config)
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

    scheduler = Werk::ParallelScheduler.new(config)

    expect_raises(Werk::Error, "Job 'missing' is not defined!") do
      scheduler.get_plan("main")
    end
  end

  it "should handle diamond dependencies" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - left
            - right
        left:
          executor: local
          needs:
            - base
        right:
          executor: local
          needs:
            - base
        base:
          executor: local
          commands:
            - echo base
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("main")

    # base first, then left+right in parallel, then main
    plan.size.should eq 3
    plan[0].should eq Set{"base"}
    plan[1].should eq Set{"left", "right"}
    plan[2].should eq Set{"main"}
  end

  it "should handle deeply nested dependencies" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        a:
          executor: local
          needs:
            - b
        b:
          executor: local
          needs:
            - c
        c:
          executor: local
          needs:
            - d
        d:
          executor: local
          commands:
            - echo d
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("a")

    plan.size.should eq 4
    plan[0].should eq Set{"d"}
    plan[1].should eq Set{"c"}
    plan[2].should eq Set{"b"}
    plan[3].should eq Set{"a"}
  end

  it "should handle shared dependencies across branches" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - a
            - b
        a:
          executor: local
          needs:
            - shared
        b:
          executor: local
          needs:
            - shared
        shared:
          executor: local
          needs:
            - base
        base:
          executor: local
          commands:
            - echo base
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("main")

    # base -> shared -> a+b in parallel -> main
    plan.size.should eq 4
    plan[0].should eq Set{"base"}
    plan[1].should eq Set{"shared"}
    plan[2].should eq Set{"a", "b"}
    plan[3].should eq Set{"main"}
  end
end
