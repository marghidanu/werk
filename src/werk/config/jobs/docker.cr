module Werk
  class Config
    class DockerJob < Job
      @[YAML::Field(key: "image")]
      getter image : String = "alpine:latest"

      @[YAML::Field(key: "volumes")]
      getter volumes : Array(String) = Array(String).new

      @[YAML::Field(key: "entrypoint")]
      getter entrypoint : Array(String) = ["/bin/sh"]

      @[YAML::Field(key: "network_mode")]
      getter network_mode : String = "bridge"
    end
  end
end
