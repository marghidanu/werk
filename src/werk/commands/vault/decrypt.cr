module Werk::Commands
  class Decrypt < Admiral::Command
    define_help description: "Decrypt dotenv file values"

    def run
      files = arguments.rest
      raise "Usage: werk vault decrypt <file> [file...]" if files.empty?

      files.each { |file| raise "File not found: #{file}" unless File.exists?(file) }

      password = ::Vault.prompt_password

      files.each do |file|
        content = File.read(file)
        decrypted = ::Vault.decrypt_file(content, password)
        File.write(file, decrypted)
        puts "Decrypted values in #{file}"
      end
    ensure
      ::Vault.wipe(password) if password
    end
  end
end
