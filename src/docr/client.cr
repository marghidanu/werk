require "http/client"
require "json"
require "socket"
require "uri"

module Docr
  class Client
    Log = ::Log.for(self)

    getter host : String

    SOCKET_PATHS = [
      Path.home / ".docker" / "run" / "docker.sock",
      Path["/var/run/docker.sock"],
    ]

    def initialize(@host = self.class.detect_host)
      uri = URI.parse(@host)

      case uri.scheme
      when "unix"
        @client = HTTP::Client.new(UNIXSocket.new(uri.path))
      when "tcp", "http", "https"
        host = uri.host || raise ArgumentError.new("Missing host in Docker URI: #{@host}")
        tls = uri.scheme == "https"
        port = uri.port || (tls ? 2376 : 2375)

        @client = HTTP::Client.new(host, port, tls: tls)
      else
        raise ArgumentError.new("Unsupported Docker host scheme: #{uri.scheme}")
      end
    end

    protected def self.detect_host : String
      if ENV.has_key?("DOCKER_HOST")
        Log.debug { "Using DOCKER_HOST=#{ENV["DOCKER_HOST"]}" }

        return ENV["DOCKER_HOST"]
      end

      path = SOCKET_PATHS.find { |sock| File.exists?(sock) }
      raise DockerError.new("Docker socket not found. Set DOCKER_HOST or ensure Docker is running.") unless path

      host = URI.new(scheme: "unix", host: "", path: path.to_s).to_s
      Log.debug { "Detected Docker socket: #{host}" }
      host
    end

    def self.available? : Bool
      detect_host
      true
    rescue DockerError
      false
    end

    def images : Images
      @images ||= Images.new(self)
    end

    def containers : Containers
      @containers ||= Containers.new(self)
    end

    def call(
      method : String,
      url : String | URI,
      headers : HTTP::Headers? = nil,
      body : IO | Slice(UInt8) | String | Nil = nil,
      &
    )
      Log.debug { "#{method} #{url}" }

      resource = url.is_a?(URI) ? url.to_s : url
      @client.exec(method, resource, headers, body) do |response|
        unless response.success?
          raise DockerError.new(response.body_io.gets_to_end, response.status_code)
        end

        yield response
      end
    end
  end

  class DockerError < Exception
    getter status_code : Int32?

    def initialize(message : String, @status_code : Int32? = nil)
      super(message)
    end
  end
end
