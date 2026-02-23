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
      raise "Usage: werk vault rekey <file> [file...]" if args.empty?

      args.each { |file| raise "File not found: #{file}" unless File.exists?(file) }

      STDERR.puts "Enter current password:"
      old_password = ::Vault.prompt_password

      STDERR.puts "Enter new password:"
      new_password = ::Vault.prompt_password(confirm: true)

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
