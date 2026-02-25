module Werk::Commands
  module Decrypt
    def self.run(args : Array(String))
      parser = OptionParser.new do |opt|
        opt.banner = "Usage: werk vault decrypt <file> [file...]"
        opt.separator ""
        opt.separator "Decrypt dotenv file values"
        opt.separator ""

        opt.on("-h", "--help", "Show this help") { puts opt; exit 0 }

        opt.invalid_option { |flag| STDERR.puts "Error: Unknown option '#{flag}'"; STDERR.puts opt; exit 1 }
      end

      parser.parse(args)
      Vault.validate_files!(args)

      password = ::Vault.prompt_password

      args.each do |file|
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
