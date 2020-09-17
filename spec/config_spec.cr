require "./spec_helper"

describe "Config" do
  it "should load the config file" do
    content = File.read("werk.yml")
    config = Werk::Model::Config.from_yaml(content)

    config.is_a?(Werk::Model::Config).should eq true
  end
end
