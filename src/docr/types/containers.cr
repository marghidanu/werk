require "json"

module Docr
  module Types
    class ContainerConfig
      include JSON::Serializable

      @[JSON::Field(key: "Image")]
      property image : String

      @[JSON::Field(key: "Entrypoint")]
      property entrypoint : Array(String)?

      @[JSON::Field(key: "Cmd")]
      property cmd : Array(String)?

      @[JSON::Field(key: "WorkingDir")]
      property working_dir : String?

      @[JSON::Field(key: "Env")]
      property env : Array(String)?

      @[JSON::Field(key: "Labels")]
      property labels : Hash(String, String)?

      @[JSON::Field(key: "HostConfig")]
      property host_config : HostConfig?

      def initialize(
        @image,
        @entrypoint = nil,
        @cmd = nil,
        @working_dir = nil,
        env : Hash(String, String)? = nil,
        @labels = nil,
        @host_config = nil,
      )
        @env = env.try &.map { |k, v| "#{k}=#{v}" }
      end
    end

    class HostConfig
      include JSON::Serializable

      @[JSON::Field(key: "NetworkMode")]
      property network_mode : String?

      @[JSON::Field(key: "Binds")]
      property binds : Array(String)?

      def initialize(@network_mode = nil, @binds = nil)
      end
    end

    struct CreateContainerResponse
      include JSON::Serializable

      @[JSON::Field(key: "Id")]
      getter id : String

      @[JSON::Field(key: "Warnings")]
      getter warnings : Array(String)?
    end

    struct WaitResponse
      include JSON::Serializable

      @[JSON::Field(key: "StatusCode")]
      getter status_code : Int32
    end

    struct ContainerSummary
      include JSON::Serializable

      @[JSON::Field(key: "Id")]
      getter id : String

      @[JSON::Field(key: "Names")]
      getter names : Array(String)?

      @[JSON::Field(key: "Labels")]
      getter labels : Hash(String, String)?

      @[JSON::Field(key: "State")]
      getter state : String?
    end
  end
end
