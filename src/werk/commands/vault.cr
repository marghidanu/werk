require "./vault/*"

module Werk::Commands
  module Vault
    def self.run(args : Array(String))
      if args.empty?
        print_help
        return
      end

      case args.shift
      when "encrypt"
        Werk::Commands::Encrypt.run(args)
      when "decrypt"
        Werk::Commands::Decrypt.run(args)
      when "rekey"
        Werk::Commands::Rekey.run(args)
      when "--help", "-h"
        print_help
      else
        STDERR.puts "Unknown vault command. Use 'werk vault --help' for usage."
        exit 1
      end
    end

    private def self.print_help
      puts "Usage: werk vault <command> [options]"
      puts
      puts "Manage encrypted dotenv files"
      puts
      puts "Commands:"
      puts "  encrypt   Encrypt dotenv file values"
      puts "  decrypt   Decrypt dotenv file values"
      puts "  rekey     Re-encrypt dotenv files with a new password"
      puts
      puts "Use 'werk vault <command> --help' for more information on a command."
    end
  end
end
