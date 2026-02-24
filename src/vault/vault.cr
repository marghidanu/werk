require "openssl"
require "openssl/hmac"
require "base64"
require "random/secure"

module Vault
  Log = ::Log.for(self)

  class Error < Exception; end

  # Stores a password XOR'd with a random pad so plaintext never
  # sits in memory. A memory dump would show random bytes.
  class ObfuscatedPassword
    @pad : Bytes
    @data : Bytes

    def initialize(plaintext : String)
      size = plaintext.bytesize
      @pad = Random::Secure.random_bytes(size)
      @data = Bytes.new(size)
      size.times { |i| @data[i] = plaintext.to_unsafe[i] ^ @pad[i] }
      # Wipe the original plaintext string
      plaintext.to_unsafe.clear(size)
    end

    # Temporarily reveal the password, yield it, then wipe the copy.
    def reveal(& : String ->) : Nil
      size = @data.size
      buf = Bytes.new(size)
      size.times { |i| buf[i] = @data[i] ^ @pad[i] }
      password = String.new(buf)
      begin
        yield password
      ensure
        buf.to_unsafe.clear(size)
        password.to_unsafe.clear(size)
      end
    end

    # Wipe all internal buffers.
    def wipe : Nil
      @data.to_unsafe.clear(@data.size)
      @pad.to_unsafe.clear(@pad.size)
    end
  end

  ENCRYPTED_PREFIX  = "encrypted:"
  PBKDF2_ITERATIONS = 600_000
  CIPHER_KEY_SIZE   =      32 # AES-256
  HMAC_KEY_SIZE     =      32 # HMAC-SHA256
  SALT_SIZE         =      16
  IV_SIZE           =      16 # AES-CBC block size

  # Encrypt a plaintext value with a password.
  # Uses AES-256-CBC + HMAC-SHA256 (Encrypt-then-MAC).
  # Returns "encrypted:" + Base64(salt[16] + iv[16] + hmac[32] + ciphertext[N])
  def self.encrypt_value(plaintext : String, password : String) : String
    salt = Random::Secure.random_bytes(SALT_SIZE)
    iv = Random::Secure.random_bytes(IV_SIZE)
    cipher_key, hmac_key = derive_keys(password, salt)

    cipher = OpenSSL::Cipher.new("aes-256-cbc")
    cipher.encrypt
    cipher.key = cipher_key
    cipher.iv = iv

    encrypted = IO::Memory.new
    encrypted.write(cipher.update(plaintext))
    encrypted.write(cipher.final)
    ciphertext = encrypted.to_slice

    # HMAC over iv + ciphertext (Encrypt-then-MAC)
    hmac = OpenSSL::HMAC.digest(OpenSSL::Algorithm::SHA256, hmac_key, iv + ciphertext)

    blob = IO::Memory.new
    blob.write(salt)
    blob.write(iv)
    blob.write(hmac)
    blob.write(ciphertext)

    ENCRYPTED_PREFIX + Base64.strict_encode(blob.to_slice)
  ensure
    wipe(cipher_key) if cipher_key
    wipe(hmac_key) if hmac_key
  end

  # Decrypt an "encrypted:..." value with a password.
  # Raises Vault::Error on wrong password or tampered data.
  def self.decrypt_value(value : String, password : String) : String
    raise Error.new("Value is not encrypted") unless encrypted?(value)

    raw = Base64.decode(value[ENCRYPTED_PREFIX.size..])
    min_size = SALT_SIZE + IV_SIZE + HMAC_KEY_SIZE
    raise Error.new("Encrypted data too short") if raw.size < min_size

    salt = raw[0, SALT_SIZE]
    iv = raw[SALT_SIZE, IV_SIZE]
    stored_hmac = raw[SALT_SIZE + IV_SIZE, HMAC_KEY_SIZE]
    ciphertext = raw[SALT_SIZE + IV_SIZE + HMAC_KEY_SIZE, raw.size - min_size]

    cipher_key, hmac_key = derive_keys(password, salt)

    # Verify HMAC before decrypting (Encrypt-then-MAC)
    computed_hmac = OpenSSL::HMAC.digest(OpenSSL::Algorithm::SHA256, hmac_key, iv + ciphertext)
    raise Error.new("Decryption failed: wrong password or corrupted data") unless secure_compare(stored_hmac, computed_hmac)

    cipher = OpenSSL::Cipher.new("aes-256-cbc")
    cipher.decrypt
    cipher.key = cipher_key
    cipher.iv = iv

    decrypted = IO::Memory.new
    decrypted.write(cipher.update(ciphertext))
    decrypted.write(cipher.final)

    String.new(decrypted.to_slice)
  rescue ex : OpenSSL::Cipher::Error
    raise Error.new("Decryption failed: wrong password or corrupted data")
  ensure
    wipe(cipher_key) if cipher_key
    wipe(hmac_key) if hmac_key
  end

  # Check if a value is encrypted.
  def self.encrypted?(value : String) : Bool
    value.starts_with?(ENCRYPTED_PREFIX)
  end

  # Encrypt all plaintext values in a dotenv file content string.
  # Returns {encrypted_content, skipped_keys}.
  def self.encrypt_file(content : String, password : String) : {String, Array(String)}
    skipped = [] of String

    encrypted = content.each_line.map do |line|
      if line =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/
        key, value = $1, $2
        unquoted = unquote(value)
        if encrypted?(unquoted)
          skipped << key
          line
        else
          "#{key}=\"#{encrypt_value(unquoted, password)}\""
        end
      else
        line
      end
    end.join("\n")

    {encrypted, skipped}
  end

  # Decrypt all encrypted values in a dotenv file content string.
  def self.decrypt_file(content : String, password : String) : String
    content.each_line.map do |line|
      if line =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/
        key, value = $1, $2
        unquoted = unquote(value)
        if encrypted?(unquoted)
          "#{key}=#{decrypt_value(unquoted, password)}"
        else
          line
        end
      else
        line
      end
    end.join("\n")
  end

  # Decrypt encrypted values in a loaded hash (from Dotenv.load).
  def self.decrypt_hash(vars : Hash(String, String), password : String) : Hash(String, String)
    vars.transform_values do |v|
      encrypted?(v) ? decrypt_value(v, password) : v
    end
  end

  # Check if any values in a hash are encrypted.
  def self.has_encrypted?(vars : Hash(String, String)) : Bool
    vars.any? { |_, v| encrypted?(v) }
  end

  # Prompt for password on STDERR (hidden input).
  def self.prompt_password(confirm : Bool = false, prompt : String = "Password: ") : String
    raise Error.new("No TTY available for password prompt") unless STDIN.tty?

    STDERR.print prompt
    STDERR.flush
    password = STDIN.noecho { |io| io.gets.try(&.chomp) || "" }
    STDERR.puts

    raise Error.new("Password cannot be empty") if password.empty?

    if confirm
      STDERR.print "Confirm password: "
      STDERR.flush
      confirmation = STDIN.noecho { |io| io.gets.try(&.chomp) || "" }
      STDERR.puts

      raise Error.new("Passwords do not match") unless password == confirmation
    end

    password
  end

  # Load dotenv files, decrypting each file with its own password.
  # Tries previously entered passwords first before prompting.
  # Passwords are stored obfuscated (XOR'd with random pad) in memory.
  # Returns merged vars and updated password cache.
  def self.load_dotenv_files(
    files : Enumerable(String),
    passwords : Array(ObfuscatedPassword) = [] of ObfuscatedPassword,
  ) : {Hash(String, String), Array(ObfuscatedPassword)}
    vars = Hash(String, String).new

    files.each do |file|
      file_vars = Dotenv.load(file)

      if has_encrypted?(file_vars)
        STDERR.puts "Decrypting #{file}..."
        decrypted = false

        # Try cached passwords first
        passwords.each do |cached|
          cached.reveal do |plain|
            file_vars = Vault.decrypt_hash(Dotenv.load(file), plain)
          end
          decrypted = true
          break
        rescue Vault::Error
          next
        end

        # Prompt for a new password if none worked
        unless decrypted
          plain = prompt_password(prompt: "Password for #{file}: ")
          file_vars = Vault.decrypt_hash(Dotenv.load(file), plain)
          passwords << ObfuscatedPassword.new(plain)
        end
      end

      vars.merge!(file_vars)
    end

    {vars, passwords}
  end

  # Derive two keys from a password: one for AES, one for HMAC.
  private def self.derive_keys(password : String, salt : Bytes) : {Bytes, Bytes}
    derived = OpenSSL::PKCS5.pbkdf2_hmac(
      password,
      salt,
      PBKDF2_ITERATIONS,
      OpenSSL::Algorithm::SHA256,
      CIPHER_KEY_SIZE + HMAC_KEY_SIZE
    )
    {derived[0, CIPHER_KEY_SIZE], derived[CIPHER_KEY_SIZE, HMAC_KEY_SIZE]}
  end

  # Constant-time comparison to prevent timing attacks.
  private def self.secure_compare(a : Bytes, b : Bytes) : Bool
    return false unless a.size == b.size
    result = 0_u8
    a.size.times { |i| result |= a[i] ^ b[i] }
    result == 0
  end

  # Zero out a Bytes buffer to remove sensitive data from memory.
  def self.wipe(bytes : Bytes) : Nil
    bytes.to_unsafe.clear(bytes.size)
  end

  # Zero out a String's backing memory to remove sensitive data.
  # Safe with Boehm GC (non-moving collector).
  def self.wipe(str : String) : Nil
    str.to_unsafe.clear(str.bytesize)
  end

  # Wipe all cached obfuscated passwords.
  def self.wipe_passwords(passwords : Array(ObfuscatedPassword)) : Nil
    passwords.each(&.wipe)
    passwords.clear
  end

  private def self.unquote(value : String) : String
    v = value.strip
    if (v.starts_with?('"') && v.ends_with?('"')) || (v.starts_with?('\'') && v.ends_with?('\''))
      v[1..-2]
    else
      v
    end
  end
end
