module Werk::Commands
  class Encrypt < Admiral::Command
    define_help description: "Encrypt dotenv file values"

    def run
      files = arguments.rest
      raise "Usage: werk vault encrypt <file> [file...]" if files.empty?

      files.each { |file| raise "File not found: #{file}" unless File.exists?(file) }

      password = ::Vault.prompt_password(confirm: true)

      files.each do |file|
        content = File.read(file)
        encrypted, skipped = ::Vault.encrypt_file(content, password)
        File.write(file, encrypted)
        puts "Encrypted values in #{file}"
        skipped.each { |key| puts "  Skipped #{key} (already encrypted)" }
      end
    ensure
      ::Vault.wipe(password) if password
    end
  end
end
