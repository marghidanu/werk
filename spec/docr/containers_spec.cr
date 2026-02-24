require "../spec_helper"

describe Docr::Containers do
  it "should capture stdout and stderr logs" do
    pending!("Docker not available") unless Docr::Client.available?

    client = Docr::Client.new
    client.containers.delete("docr-test-logs", force: true) rescue nil

    container = client.containers.create(
      "docr-test-logs",
      Docr::ContainerConfig.new(
        image: "alpine:latest",
        cmd: ["sh", "-c", "echo hello from docker && echo error message >&2"],
      )
    )

    begin
      client.containers.start(container.id)

      output = IO::Memory.new
      client.containers.logs(container.id, output, follow: true, stdout: true, stderr: true)

      status = client.containers.wait(container.id)

      status.status_code.should eq 0
      output.to_s.should contain "hello from docker"
      output.to_s.should contain "error message"
    ensure
      client.containers.delete(container.id, force: true)
    end
  end

  it "should capture non-zero exit code" do
    pending!("Docker not available") unless Docr::Client.available?

    client = Docr::Client.new
    client.containers.delete("docr-test-exit", force: true) rescue nil

    container = client.containers.create(
      "docr-test-exit",
      Docr::ContainerConfig.new(
        image: "alpine:latest",
        cmd: ["sh", "-c", "exit 42"],
      )
    )

    begin
      client.containers.start(container.id)
      status = client.containers.wait(container.id)

      status.status_code.should eq 42
    ensure
      client.containers.delete(container.id, force: true)
    end
  end
end

describe Docr::ContainerConfig do
  it "should serialize to JSON with PascalCase keys" do
    config = Docr::ContainerConfig.new(
      image: "alpine:latest",
      cmd: ["/bin/sh"],
      working_dir: "/opt",
      env: {"FOO" => "bar"},
      labels: {"app" => "test"},
    )

    json = JSON.parse(config.to_json)

    json["Image"].should eq "alpine:latest"
    json["Cmd"].should eq ["/bin/sh"]
    json["WorkingDir"].should eq "/opt"
    json["Env"].should eq ["FOO=bar"]
    json["Labels"]["app"].should eq "test"
  end

  it "should omit nil fields" do
    config = Docr::ContainerConfig.new(image: "alpine")

    json = JSON.parse(config.to_json)

    json["Image"].should eq "alpine"
    json["Cmd"]?.should be_nil
    json["Env"]?.should be_nil
  end
end

describe Docr::HostConfig do
  it "should serialize binds and network mode" do
    host_config = Docr::HostConfig.new(
      network_mode: "host",
      binds: ["/src:/dst"],
    )

    json = JSON.parse(host_config.to_json)

    json["NetworkMode"].should eq "host"
    json["Binds"].should eq ["/src:/dst"]
  end
end

describe Docr::CreateContainerResponse do
  it "should deserialize from JSON" do
    response = Docr::CreateContainerResponse.from_json(%({"Id": "abc123", "Warnings": ["warn1"]}))

    response.id.should eq "abc123"
    response.warnings.should eq ["warn1"]
  end
end

describe Docr::WaitResponse do
  it "should deserialize status code" do
    response = Docr::WaitResponse.from_json(%({"StatusCode": 0}))

    response.status_code.should eq 0
  end

  it "should deserialize non-zero status code" do
    response = Docr::WaitResponse.from_json(%({"StatusCode": 137}))

    response.status_code.should eq 137
  end
end

describe Docr::ContainerSummary do
  it "should deserialize from JSON" do
    response = Docr::ContainerSummary.from_json(%({"Id": "abc123", "Names": ["/my-container"], "State": "running"}))

    response.id.should eq "abc123"
    response.names.should eq ["/my-container"]
    response.state.should eq "running"
  end
end
