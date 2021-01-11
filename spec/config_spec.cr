require "./spec_helper"

describe "Config" do
  it "should load the config file" do
    config = Werk::Model::Config.load_file("werk.yml")

    config.is_a?(Werk::Model::Config).should eq true
  end

  it "should fail for non existing file" do
    expect_raises(Exception, "Configuration file missing!") do
      Werk::Model::Config.load_file("werk.yaml")
    end
  end

  it "should fail for empty content" do
    temp = File.tempfile
    File.write(temp.path, "")

    expect_raises(Exception, "Configuration file is empty!") do
      Werk::Model::Config.load_file(temp.path)
    end

    temp.delete
  end

  it "should fail with parsing error" do
    temp = File.tempfile
    File.write(temp.path, "jobs: []")

    expect_raises(Exception, "Parse error at line 1, column 7") do
      Werk::Model::Config.load_file(temp.path)
    end

    temp.delete
  end
end
