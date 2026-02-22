module Werk::Commands
  class Rekey < Admiral::Command
    define_help description: "Re-encrypt dotenv files with a new password"

    def run
      files = arguments.rest
      raise "Usage: werk vault rekey <file> [file...]" if files.empty?

      files.each { |file| raise "File not found: #{file}" unless File.exists?(file) }

      STDERR.puts "Enter current password:"
      old_password = ::Vault.prompt_password

      STDERR.puts "Enter new password:"
      new_password = ::Vault.prompt_password(confirm: true)

      files.each do |file|
        content = File.read(file)
        decrypted = ::Vault.decrypt_file(content, old_password)
        encrypted, _skipped = ::Vault.encrypt_file(decrypted, new_password)
        File.write(file, encrypted)
        puts "Re-encrypted values in #{file}"
      end
    ensure
      ::Vault.wipe(old_password) if old_password
      ::Vault.wipe(new_password) if new_password
    end
  end
end
