require "./vault/*"

module Werk::Commands
  class Vault < Admiral::Command
    define_help description: "Manage encrypted dotenv files"

    register_sub_command encrypt : Werk::Commands::Encrypt,
      description: "Encrypt dotenv file values"

    register_sub_command decrypt : Werk::Commands::Decrypt,
      description: "Decrypt dotenv file values"

    register_sub_command rekey : Werk::Commands::Rekey,
      description: "Re-encrypt dotenv files with a new password"

    def run
      puts help
    end
  end
end
