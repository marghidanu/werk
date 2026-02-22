require "../spec_helper"

describe Vault do
  describe ".encrypt_value / .decrypt_value" do
    it "round-trips a plaintext value" do
      password = "test-password-123"
      plaintext = "my-secret-value"

      encrypted = Vault.encrypt_value(plaintext, password)
      encrypted.should start_with(Vault::ENCRYPTED_PREFIX)

      decrypted = Vault.decrypt_value(encrypted, password)
      decrypted.should eq plaintext
    end

    it "produces different ciphertext for same input" do
      password = "test-password"
      plaintext = "same-value"

      a = Vault.encrypt_value(plaintext, password)
      b = Vault.encrypt_value(plaintext, password)

      a.should_not eq b # Different salt + IV each time
    end

    it "handles empty string" do
      password = "test-password"
      encrypted = Vault.encrypt_value("", password)
      Vault.decrypt_value(encrypted, password).should eq ""
    end

    it "handles unicode content" do
      password = "test-password"
      plaintext = "hello world!"

      encrypted = Vault.encrypt_value(plaintext, password)
      Vault.decrypt_value(encrypted, password).should eq plaintext
    end

    it "raises on wrong password" do
      encrypted = Vault.encrypt_value("secret", "correct-password")

      expect_raises(Vault::Error, /wrong password/) do
        Vault.decrypt_value(encrypted, "wrong-password")
      end
    end

    it "raises on tampered data" do
      encrypted = Vault.encrypt_value("secret", "password")
      # Corrupt one character in the base64 payload
      tampered = encrypted[0..-3] + "AA"

      expect_raises(Vault::Error, /wrong password|corrupted/) do
        Vault.decrypt_value(tampered, "password")
      end
    end
  end

  describe ".encrypted?" do
    it "returns true for encrypted values" do
      Vault.encrypted?("encrypted:abc123").should be_true
    end

    it "returns false for plaintext values" do
      Vault.encrypted?("just-a-value").should be_false
    end

    it "returns false for empty string" do
      Vault.encrypted?("").should be_false
    end
  end

  describe ".encrypt_file / .decrypt_file" do
    it "encrypts and decrypts a dotenv file" do
      password = "file-password"
      content = "DB_HOST=localhost\nDB_PASS=secret123"

      encrypted_content, skipped = Vault.encrypt_file(content, password)

      # Key names should be visible, values quoted
      encrypted_content.should contain("DB_HOST=\"encrypted:")
      encrypted_content.should contain("DB_PASS=\"encrypted:")
      skipped.should be_empty

      decrypted_content = Vault.decrypt_file(encrypted_content, password)
      decrypted_content.should eq "DB_HOST=localhost\nDB_PASS=secret123"
    end

    it "preserves comments and blank lines" do
      password = "test"
      content = "# This is a comment\n\nKEY=value"

      encrypted, skipped = Vault.encrypt_file(content, password)
      encrypted.should start_with("# This is a comment\n\n")
      skipped.should be_empty

      decrypted = Vault.decrypt_file(encrypted, password)
      decrypted.should eq content
    end

    it "skips already encrypted values" do
      password = "test"
      already = "KEY=encrypted:existingdata"

      result, skipped = Vault.encrypt_file(already, password)
      result.should eq already
      skipped.should eq ["KEY"]
    end
  end

  describe ".decrypt_hash" do
    it "decrypts encrypted values in a hash" do
      password = "hash-password"
      encrypted_val = Vault.encrypt_value("secret", password)

      vars = {
        "PLAIN"     => "hello",
        "ENCRYPTED" => encrypted_val,
      }

      result = Vault.decrypt_hash(vars, password)
      result["PLAIN"].should eq "hello"
      result["ENCRYPTED"].should eq "secret"
    end
  end

  describe ".has_encrypted?" do
    it "returns true when hash contains encrypted values" do
      vars = {"KEY" => "encrypted:something"}
      Vault.has_encrypted?(vars).should be_true
    end

    it "returns false when hash has no encrypted values" do
      vars = {"KEY" => "plaintext"}
      Vault.has_encrypted?(vars).should be_false
    end

    it "returns false for empty hash" do
      Vault.has_encrypted?(Hash(String, String).new).should be_false
    end
  end
end
