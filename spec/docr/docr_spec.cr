require "../spec_helper"

describe Docr::Utils do
  describe ".parse_repository_tag" do
    it "should default to latest tag" do
      repo, tag = Docr::Utils.parse_repository_tag("alpine")

      repo.should eq "alpine"
      tag.should eq "latest"
    end

    it "should parse explicit tag" do
      repo, tag = Docr::Utils.parse_repository_tag("alpine:3.18")

      repo.should eq "alpine"
      tag.should eq "3.18"
    end

    it "should parse namespaced image" do
      repo, tag = Docr::Utils.parse_repository_tag("my/repo:v1.0")

      repo.should eq "my/repo"
      tag.should eq "v1.0"
    end

    it "should handle registry with port" do
      repo, tag = Docr::Utils.parse_repository_tag("registry:5000/image:tag")

      repo.should eq "registry:5000/image"
      tag.should eq "tag"
    end

    it "should handle registry with port and no tag" do
      repo, tag = Docr::Utils.parse_repository_tag("registry:5000/image")

      repo.should eq "registry:5000/image"
      tag.should eq "latest"
    end
  end
end

describe Docr::DockerError do
  it "should include status code and message" do
    error = Docr::DockerError.new("no such container", 404)

    error.status_code.should eq 404
    error.message.should eq "no such container"
  end

  it "should default status code to nil" do
    error = Docr::DockerError.new("something went wrong")

    error.status_code.should be_nil
    error.message.should eq "something went wrong"
  end
end
