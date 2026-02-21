require "http/client"
require "json"
require "socket"
require "uri"

module Docr
  class Client
    Log = ::Log.for(self)

    getter host : String
    getter api_version : String

    SOCKET_PATHS = [
      Path.home / ".docker" / "run" / "docker.sock",
      Path["/var/run/docker.sock"],
    ]

    def initialize(@host = self.class.detect_host, @api_version = "v1.47")
      uri = URI.parse(@host)

      case uri.scheme
      when "unix"
        @http_client = HTTP::Client.new(UNIXSocket.new(uri.path))
      when "tcp", "http", "https"
        host = uri.host || raise ArgumentError.new("Missing host in Docker URI: #{@host}")
        tls = uri.scheme == "https"
        @http_client = HTTP::Client.new(host, uri.port || (tls ? 2376 : 2375), tls: tls)
      else
        raise ArgumentError.new("Unsupported Docker host scheme: #{uri.scheme}")
      end
    end

    def self.detect_host : String
      if ENV.has_key?("DOCKER_HOST")
        Log.debug { "Using DOCKER_HOST=#{ENV["DOCKER_HOST"]}" }
        return ENV["DOCKER_HOST"]
      end

      path = SOCKET_PATHS.find { |sock| File.exists?(sock) }
      raise "Docker socket not found. Set DOCKER_HOST or ensure Docker is running." unless path

      host = URI.new(scheme: "unix", host: "", path: path.to_s).to_s
      Log.debug { "Detected Docker socket: #{host}" }
      host
    end

    def images : Images
      @images ||= Images.new(self)
    end

    def containers : Containers
      @containers ||= Containers.new(self)
    end

    def request(method : String, path : String, params : URI::Params? = nil, body : String? = nil, &)
      headers = HTTP::Headers{"Content-Type" => "application/json"} if body

      uri = URI.new(path: "/#{@api_version}#{path}")
      uri.query_params = params if params

      @http_client.exec(method, uri.to_s, headers: headers, body: body) do |response|
        unless response.success?
          raise DockerError.new(response.status_code, response.body_io.gets_to_end)
        end
        yield response
      end
    end
  end

  class DockerError < Exception
    getter status_code : Int32

    def initialize(@status_code, body : String)
      super("Docker API error (#{@status_code}): #{body}")
    end
  end
end
