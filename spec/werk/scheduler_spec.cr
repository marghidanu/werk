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

    expect_raises(Exception, "Job 'missing' is not defined!") do
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

describe Werk::SequentialScheduler do
  it "should generate one job per stage" do
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

    scheduler = Werk::SequentialScheduler.new(config)
    plan = scheduler.get_plan("main")

    # Each stage should have exactly one job
    plan.each do |stage|
      stage.size.should eq 1
    end

    # Should have 3 stages (lint, test, main) instead of 2
    plan.size.should eq 3

    # All jobs should be present
    all_jobs = plan.flat_map(&.to_a)
    all_jobs.should contain "lint"
    all_jobs.should contain "test"
    all_jobs.should contain "main"

    # main should be last
    plan.last.should eq Set{"main"}
  end

  it "should preserve dependency order" do
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

    scheduler = Werk::SequentialScheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 3
    plan[0].should eq Set{"test"}
    plan[1].should eq Set{"build"}
    plan[2].should eq Set{"main"}
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

    scheduler = Werk::SequentialScheduler.new(config)

    expect_raises(Exception, "Job 'missing' is not defined!") do
      scheduler.get_plan("main")
    end
  end

  it "should generate a single stage for a single job" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo hello
    ))

    scheduler = Werk::SequentialScheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 1
    plan[0].should eq Set{"main"}
  end

  it "should flatten diamond dependencies into sequential stages" do
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

    scheduler = Werk::SequentialScheduler.new(config)
    plan = scheduler.get_plan("main")

    # Each stage should have exactly one job
    plan.each do |stage|
      stage.size.should eq 1
    end

    # Should have 4 stages: base, left, right, main
    plan.size.should eq 4

    # base must come before left and right, main must be last
    all_jobs = plan.map(&.first)
    all_jobs.index!("base").should be < all_jobs.index!("left")
    all_jobs.index!("base").should be < all_jobs.index!("right")
    plan.last.should eq Set{"main"}
  end

  it "should produce more stages than parallel for independent jobs" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - a
            - b
            - c
        a:
          executor: local
          commands:
            - echo a
        b:
          executor: local
          commands:
            - echo b
        c:
          executor: local
          commands:
            - echo c
    ))

    parallel = Werk::ParallelScheduler.new(config)
    sequential = Werk::SequentialScheduler.new(config)

    parallel_plan = parallel.get_plan("main")
    sequential_plan = sequential.get_plan("main")

    # Parallel: {a,b,c} -> {main} = 2 stages
    parallel_plan.size.should eq 2

    # Sequential: {a} -> {b} -> {c} -> {main} = 4 stages
    sequential_plan.size.should eq 4

    sequential_plan.size.should be > parallel_plan.size
  end
end
