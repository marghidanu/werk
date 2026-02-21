require "../spec_helper"

describe "Job#script_content" do
  it "should join commands with newlines" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
          commands:
            - echo hello
            - echo world
    ))

    config.jobs["main"].script_content.should eq "echo hello\necho world"
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

    config.jobs["main"].script_content.should eq "ls -la"
  end

  it "should handle empty commands" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        main:
          executor: local
    ))

    config.jobs["main"].script_content.should eq ""
  end
end
