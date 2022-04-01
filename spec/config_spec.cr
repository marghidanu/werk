require "./spec_helper"

describe "Config" do
  it "empty" do
    expect_raises(Exception, "Empty configuration!") do
      Werk::Config.load_string("")
    end
  end

  it "invalid" do
    expect_raises(Exception, /^Parse error/) do
      Werk::Config.load_string(%(
        version: 1
        jobs:
          main:
            executor: shell
      ))
    end
  end

  it "valid" do
    config = Werk::Config.load_string(%(
      version: 1.0

      jobs:
        shell:
          executor: local

        container:
          executor: docker
    ))

    config.should be_a Werk::Config
    config.version.should eq "1.0"
    config.jobs.keys.should eq ["shell", "container"]

    config.jobs["shell"].should be_a Werk::Jobs::Local
    config.jobs["container"].should be_a Werk::Jobs::Docker
  end

  it "should load the config file" do
    config = Werk::Config.load_file("werk.yml")
    config.should be_a Werk::Config
  end

  it "should fail for non existing file" do
    expect_raises(Exception, "Configuration file missing!") do
      Werk::Config.load_file("werk.yaml")
    end
  end
end
