module Werk::Utils
  module Redactor
    Log = ::Log.for(self)

    REDACT_CHAR = 'X'

    @@scanner : Gitleaks::Scanner?

    begin
      @@scanner = Gitleaks::Scanner.new
    rescue ex
      Log.warn { "Secret redaction disabled: #{ex.message}" }
      @@scanner = nil
    end

    def self.redact(text : String) : String
      scanner = @@scanner
      return text if scanner.nil? || text.empty?

      findings = scanner.scan(text)
      return text if findings.empty?

      Log.debug { "Redacted #{findings.size} secret(s) from output" }

      result = text
      findings.each do |finding|
        mask = finding.secret.gsub(/[^\n]/, REDACT_CHAR)
        result = result.gsub(finding.secret, mask)
      end

      result
    end
  end
end
