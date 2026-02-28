module ShellCheck
  struct Finding
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    getter file : String
    getter line : Int32

    @[JSON::Field(key: "endLine")]
    getter end_line : Int32

    getter column : Int32

    @[JSON::Field(key: "endColumn")]
    getter end_column : Int32

    getter level : String
    getter code : Int32
    getter message : String
  end
end
