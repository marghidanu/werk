module Werk::Commands::Vault::Encrypt
  def self.run(args : Array(String))
    parser = OptionParser.new do |opt|
      opt.banner = "Usage: werk vault encrypt <file> [file...]"
      opt.separator ""
      opt.separator "Encrypt dotenv file values"
      opt.separator ""

      opt.on("-h", "--help", "Show this help") { puts opt; exit 0 }

      opt.invalid_option { |flag| STDERR.puts "Error: Unknown option '#{flag}'"; STDERR.puts opt; exit 1 }
    end

    parser.parse(args)
    Vault.validate_files!(args)

    password = ::Vault.prompt_password(confirm: true)

    args.each do |file|
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
