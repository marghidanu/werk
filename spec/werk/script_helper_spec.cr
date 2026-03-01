require "../spec_helper"

describe "Job#commands" do
  it "should parse multiple commands" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo hello
            - echo world
    ))

    config.jobs["main"].commands.should eq ["echo hello", "echo world"]
  end

  it "should handle a single command" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - ls -la
    ))

    config.jobs["main"].commands.should eq ["ls -la"]
  end

  it "should default to empty" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
    ))

    config.jobs["main"].commands.should be_empty
  end
end
