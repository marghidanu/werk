module Werk::Commands
  module Rekey
    def self.run(args : Array(String))
      parser = OptionParser.new do |opt|
        opt.banner = "Usage: werk vault rekey <file> [file...]"
        opt.separator ""
        opt.separator "Re-encrypt dotenv files with a new password"
        opt.separator ""

        opt.on("-h", "--help", "Show this help") { puts opt; exit 0 }

        opt.invalid_option { |flag| STDERR.puts "Error: Unknown option '#{flag}'"; STDERR.puts opt; exit 1 }
      end

      parser.parse(args)
      Vault.validate_files!(args)

      old_password = ::Vault.prompt_password(prompt: "Current password: ")
      new_password = ::Vault.prompt_password(confirm: true, prompt: "New password: ")

      args.each do |file|
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
