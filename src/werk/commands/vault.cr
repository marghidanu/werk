require "./vault/*"

module Werk::Commands::Vault
  def self.run(args : Array(String))
    if args.empty?
      print_help
      return
    end

    case args.shift
    when "encrypt"
      Encrypt.run(args)
    when "decrypt"
      Decrypt.run(args)
    when "rekey"
      Rekey.run(args)
    when "--help", "-h"
      print_help
    else
      STDERR.puts "Unknown vault command. Use 'werk vault --help' for usage."
      exit 1
    end
  end

  protected def self.validate_files!(args : Array(String))
    raise Werk::Error.new("No files specified") if args.empty?
    args.each { |file| raise Werk::Error.new("File not found: #{file}") unless File.exists?(file) }
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
