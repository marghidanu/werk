require "uri"

module Docr
  class Images
    def initialize(@client : Client)
    end

    # Check if an image exists locally.
    def exists?(name : String) : Bool
      @client.request("GET", "/images/#{name}/json") do |response|
        response.consume_body_io
      end
      true
    rescue DockerError
      false
    end

    # Pull an image from a registry.
    def pull(repository : String, tag : String = "latest")
      params = URI::Params{"fromImage" => repository, "tag" => tag}
      @client.request("POST", "/images/create", params) do |response|
        response.consume_body_io
      end
    end
  end
end
