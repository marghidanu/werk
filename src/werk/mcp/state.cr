module Werk::Mcp::Context
  class_property config_path : String = "werk.yml"
  class_property cwd : String = "."

  def self.config : Werk::Config
    Werk::Config.load_file(@@config_path)
  end
end
