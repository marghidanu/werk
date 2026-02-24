require "../spec_helper"

describe "Config" do
  it "empty" do
    expect_raises(Werk::Error, "Empty configuration!") do
      Werk::Config.load_string("")
    end
  end

  it "invalid" do
    expect_raises(Werk::Error, /^Parse error/) do
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

    config.jobs["shell"].should be_a Werk::Config::LocalJob
    config.jobs["container"].should be_a Werk::Config::DockerJob
  end

  it "should parse docker job config fields" do
    config = Werk::Config.load_string(%(
      version: 1.0
      jobs:
        custom:
          executor: docker
          image: "node:18"
          network_mode: "host"
          entrypoint: ["/bin/bash"]
          volumes:
            - /tmp:/tmp
          commands:
            - echo hello
        defaults:
          executor: docker
    ))

    custom = config.jobs["custom"].as(Werk::Config::DockerJob)
    custom.image.should eq "node:18"
    custom.network_mode.should eq "host"
    custom.entrypoint.should eq ["/bin/bash"]
    custom.volumes.should eq ["/tmp:/tmp"]

    defaults = config.jobs["defaults"].as(Werk::Config::DockerJob)
    defaults.image.should eq "alpine:latest"
    defaults.network_mode.should eq "bridge"
    defaults.entrypoint.should eq ["/bin/sh"]
    defaults.volumes.should be_empty
  end

  it "should load the config file" do
    config = Werk::Config.load_file("werk.yml")
    config.should be_a Werk::Config
  end

  it "should fail for non existing file" do
    expect_raises(Werk::Error, "Configuration file missing!") do
      Werk::Config.load_file("werk.yaml")
    end
  end
end
