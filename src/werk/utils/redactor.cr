module Werk::Utils
  module Redactor
    Log = ::Log.for(self)

    REDACT_CHAR = 'X'

    @@scanner = Gitleaks::Scanner.new

    def self.redact(text : String) : String
      return text if text.empty?

      findings = @@scanner.scan(text)
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
