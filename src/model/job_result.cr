require "json"

module Werk::Model
  class JobResult
    include JSON::Serializable

    property name : String

    property variables : Hash(String, String)

    property content : String

    property directory : String

    property exit_code : Int32

    property output : String

    property duration : Float64

    def initialize(@name, @variables, @content, @directory, @exit_code, @output, @duration)
    end
  end
end
