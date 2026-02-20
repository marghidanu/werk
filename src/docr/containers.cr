require "uri"
require "json"

module Docr
  class Containers
    def initialize(@client : Client)
    end

    # Create a new container with the given name and configuration.
    def create(name : String, config : ContainerConfig) : CreateContainerResponse
      params = URI::Params{"name" => name}
      @client.request("POST", "/containers/create", params, body: config.to_json) do |response|
        return CreateContainerResponse.from_json(response.body_io.gets_to_end)
      end
    end

    # Start a created container.
    def start(id : String)
      @client.request("POST", "/containers/#{id}/start") do |response|
        response.consume_body_io
      end
    rescue ex : DockerError
      raise ex unless ex.status_code == 304
    end

    # Stream container logs, writing decoded output to the given IO.
    # Handles the Docker multiplexed stream format (8-byte header per frame).
    def logs(id : String, output : IO, follow : Bool = false, stdout : Bool = true, stderr : Bool = true)
      params = URI::Params{
        "follow" => follow.to_s,
        "stdout" => stdout.to_s,
        "stderr" => stderr.to_s,
      }
      @client.request("GET", "/containers/#{id}/logs", params) do |response|
        Containers.decode_stream(response.body_io, output)
      end
    end

    # Decode a Docker multiplexed stream into the given output IO.
    # Each frame: [stream_type(1), padding(3), size(4 big-endian)] followed by payload.
    def self.decode_stream(input : IO, output : IO)
      loop do
        has_next = input.peek
        break if has_next.nil? || has_next.empty?

        header = Bytes.new(8)
        input.read_fully(header)
        frame_size = IO::ByteFormat::BigEndian.decode(UInt32, header[4, 4])

        IO.copy(input, output, frame_size)
      end
    rescue IO::EOFError
    end

    # Block until a container stops, then return the exit code.
    def wait(id : String) : WaitResponse
      @client.request("POST", "/containers/#{id}/wait") do |response|
        return WaitResponse.from_json(response.body_io.gets_to_end)
      end
    end

    # Remove a container.
    def delete(id : String, force : Bool = false)
      params = URI::Params{"force" => force.to_s}
      @client.request("DELETE", "/containers/#{id}", params) do |response|
        response.consume_body_io
      end
    end

    # List containers, optionally filtered.
    def list(filters : Hash(String, Array(String))? = nil) : Array(ContainerSummary)
      params = filters ? URI::Params{"filters" => filters.to_json} : nil
      @client.request("GET", "/containers/json", params) do |response|
        return Array(ContainerSummary).from_json(response.body_io.gets_to_end)
      end
    end

    # Send a signal to a container.
    def kill(id : String, signal : String = "SIGKILL")
      params = URI::Params{"signal" => signal}
      @client.request("POST", "/containers/#{id}/kill", params) do |response|
        response.consume_body_io
      end
    end
  end
end
