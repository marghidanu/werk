require "uri"
require "json"

module Docr
  class Containers
    def initialize(@client : Client)
    end

    # Create a new container with the given name and configuration.
    def create(name : String, config : ContainerConfig) : CreateContainerResponse
      url = URI.new(
        path: "/containers/create",
        query: URI::Params{
          "name" => name,
        }
      )

      headers = HTTP::Headers{
        "Content-Type" => "application/json",
      }

      @client.call("POST", url, headers, config.to_json) do |response|
        return CreateContainerResponse.from_json(response.body_io.gets_to_end)
      end
    end

    # Start a created container.
    def start(id : String)
      url = URI.new(path: "/containers/#{id}/start")

      @client.call("POST", url) do |response|
        response.consume_body_io
      end
    end

    # Stream container logs, writing decoded output to the given IO.
    # Handles the Docker multiplexed stream format (8-byte header per frame).
    def logs(id : String, output : IO, follow : Bool = false, stdout : Bool = true, stderr : Bool = true)
      url = URI.new(
        path: "/containers/#{id}/logs",
        query: URI::Params{
          "follow" => follow.to_s,
          "stdout" => stdout.to_s,
          "stderr" => stderr.to_s,
        }
      )

      @client.call("GET", url) do |response|
        Utils.decode_stream(response.body_io, output)
      end
    end

    # Block until a container stops, then return the exit code.
    def wait(id : String) : WaitResponse
      url = URI.new(path: "/containers/#{id}/wait")

      @client.call("POST", url) do |response|
        return WaitResponse.from_json(response.body_io.gets_to_end)
      end
    end

    # Remove a container.
    def delete(id : String, force : Bool = false)
      url = URI.new(
        path: "/containers/#{id}",
        query: URI::Params{
          "force" => force.to_s,
        }
      )

      @client.call("DELETE", url) do |response|
        response.consume_body_io
      end
    end

    # List containers, optionally filtered.
    def list(filters : Hash(String, Array(String))? = nil) : Array(ContainerSummary)
      url = URI.new(
        path: "/containers/json",
        query: (filters ? URI::Params{
          "filters" => filters.to_json,
        } : nil),
      )

      @client.call("GET", url) do |response|
        return Array(ContainerSummary).from_json(response.body_io.gets_to_end)
      end
    end

    # Send a signal to a container.
    def kill(id : String, signal : String = "SIGKILL")
      url = URI.new(
        path: "/containers/#{id}/kill",
        query: URI::Params{
          "signal" => signal,
        }
      )

      @client.call("POST", url) do |response|
        response.consume_body_io
      end
    end
  end
end
