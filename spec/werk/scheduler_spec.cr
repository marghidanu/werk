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

  it "should warn but not fail for undefined job" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - missing
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 1
    plan[0].should eq Set{"main"}
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

  it "should expand wildcard needs" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - lint:*
        lint:crystal:
          executor: local
          commands:
            - echo lint crystal
        lint:dockerfile:
          executor: local
          commands:
            - echo lint dockerfile
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 2
    plan[0].should eq Set{"lint:crystal", "lint:dockerfile"}
    plan[1].should eq Set{"main"}
  end

  it "should expand wildcard needs mixed with exact names" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - lint:*
            - test
        lint:crystal:
          executor: local
          commands:
            - echo lint
        lint:dockerfile:
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
    plan[0].should eq Set{"lint:crystal", "lint:dockerfile", "test"}
    plan[1].should eq Set{"main"}
  end

  it "should warn but not fail for wildcard matching no jobs" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - nope:*
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 1
    plan[0].should eq Set{"main"}
  end

  it "should not self-match with wildcard" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        lint:
          executor: local
          needs:
            - lint:*
        lint:crystal:
          executor: local
          commands:
            - echo lint crystal
        lint:dockerfile:
          executor: local
          commands:
            - echo lint dockerfile
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("lint")

    plan.size.should eq 2
    plan[0].should eq Set{"lint:crystal", "lint:dockerfile"}
    plan[1].should eq Set{"lint"}
  end

  it "should expand ? single-character wildcard" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - phase?
        phase1:
          executor: local
          commands:
            - echo phase1
        phase2:
          executor: local
          commands:
            - echo phase2
        phase10:
          executor: local
          commands:
            - echo phase10
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 2
    # phase10 should NOT match — ? matches exactly one character
    plan[0].should eq Set{"phase1", "phase2"}
    plan[1].should eq Set{"main"}
  end

  it "should expand [...] character class" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - step[1-3]
        step1:
          executor: local
          commands:
            - echo step1
        step2:
          executor: local
          commands:
            - echo step2
        step3:
          executor: local
          commands:
            - echo step3
        step4:
          executor: local
          commands:
            - echo step4
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 2
    # step4 should NOT match — only [1-3]
    plan[0].should eq Set{"step1", "step2", "step3"}
    plan[1].should eq Set{"main"}
  end

  it "should expand {a,b} alternation" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          needs:
            - deploy:{staging,production}
        deploy:staging:
          executor: local
          commands:
            - echo staging
        deploy:production:
          executor: local
          commands:
            - echo production
        deploy:dev:
          executor: local
          commands:
            - echo dev
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("main")

    plan.size.should eq 2
    # deploy:dev should NOT match — only {staging,production}
    plan[0].should eq Set{"deploy:staging", "deploy:production"}
    plan[1].should eq Set{"main"}
  end

  it "should expand transitive wildcard dependencies" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        deploy:
          executor: local
          needs:
            - build:*
        build:frontend:
          executor: local
          needs:
            - lint:*
        build:backend:
          executor: local
          commands:
            - echo build backend
        lint:eslint:
          executor: local
          commands:
            - echo eslint
        lint:tsc:
          executor: local
          commands:
            - echo tsc
    ))

    scheduler = Werk::ParallelScheduler.new(config)
    plan = scheduler.get_plan("deploy")

    plan.size.should eq 3
    plan[0].should eq Set{"lint:eslint", "lint:tsc"}
    plan[1].should eq Set{"build:frontend", "build:backend"}
    plan[2].should eq Set{"deploy"}
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
