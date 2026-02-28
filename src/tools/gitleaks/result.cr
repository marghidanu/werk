module Gitleaks
  struct Result
    include JSON::Serializable

    @[JSON::Field(key: "RuleID")]
    getter rule_id : String

    @[JSON::Field(key: "Description")]
    getter description : String

    @[JSON::Field(key: "StartLine")]
    getter start_line : Int32

    @[JSON::Field(key: "EndLine")]
    getter end_line : Int32

    @[JSON::Field(key: "StartColumn")]
    getter start_column : Int32

    @[JSON::Field(key: "EndColumn")]
    getter end_column : Int32

    @[JSON::Field(key: "Match")]
    getter match : String

    @[JSON::Field(key: "Secret")]
    getter secret : String

    @[JSON::Field(key: "File")]
    getter file : String

    @[JSON::Field(key: "Entropy")]
    getter entropy : Float64

    @[JSON::Field(key: "Fingerprint")]
    getter fingerprint : String

    @[JSON::Field(key: "Tags")]
    getter tags : Array(String)
  end
end
