require "../spec_helper"

describe Gitleaks::Scanner do
  describe "#initialize" do
    it "should create an instance when gitleaks is available" do
      scanner = Gitleaks::Scanner.new
      scanner.should be_a Gitleaks::Scanner
    end
  end

  describe "#version" do
    it "should return a version string" do
      scanner = Gitleaks::Scanner.new
      version = scanner.version
      version.should match(/^\d+\.\d+\.\d+$/)
    end
  end

  describe "#scan" do
    it "should return empty array for empty text" do
      scanner = Gitleaks::Scanner.new
      scanner.scan("").should be_empty
    end

    it "should return empty array for clean text" do
      scanner = Gitleaks::Scanner.new
      scanner.scan("Hello, world!").should be_empty
    end

    it "should detect a Stripe API key" do
      scanner = Gitleaks::Scanner.new
      results = scanner.scan("STRIPE_KEY=sk_live_4eC39HqLyjWDarjtT1zdp7dc")
      results.should_not be_empty
      results.any? { |res| res.rule_id == "stripe-access-token" }.should be_true
    end

    it "should detect a Slack bot token" do
      scanner = Gitleaks::Scanner.new
      results = scanner.scan("SLACK_TOKEN=xoxb-123456789012-1234567890123-abcdefghijklmnopqrstuvwx")
      results.should_not be_empty
      results.any? { |res| res.rule_id == "slack-bot-token" }.should be_true
    end

    it "should detect a GitLab PAT" do
      scanner = Gitleaks::Scanner.new
      results = scanner.scan("GITLAB_PAT=glpat-ABCDEFGHIJKLMNOPQRST")
      results.should_not be_empty
      results.any? { |res| res.rule_id == "gitlab-pat" }.should be_true
    end

    it "should detect a private key" do
      scanner = Gitleaks::Scanner.new
      text = <<-KEY
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEA04up8hoqzS1+APIB0RhjXyObwHQnOzhAk4Bd7SOLOperands
      QZ9LkoGJqrUmDDDDqvHsRPO2F0LQHBQQSP4CE+EbNTOMi7BVHM6YAII04ofLe43
      hRPK5DP8pOEqoSORbi41VN0Rf6RkSfPMcrNbGJKsPD+9RJjOJM3Yf5HRtWEPjL+z
      -----END RSA PRIVATE KEY-----
      KEY
      results = scanner.scan(text)
      results.should_not be_empty
      results.any? { |res| res.rule_id == "private-key" }.should be_true
    end

    it "should detect a database connection URL" do
      scanner = Gitleaks::Scanner.new
      results = scanner.scan("postgres://admin:s3cRetP4ss@db.example.com:5432/myapp")
      results.should_not be_empty
      results.any? { |res| res.rule_id == "database-connection-url" }.should be_true
    end

    it "should detect a JWT token" do
      scanner = Gitleaks::Scanner.new
      results = scanner.scan("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U")
      results.should_not be_empty
      results.any? { |res| res.rule_id =~ /jwt/ }.should be_true
    end

    it "should detect an environment variable secret" do
      scanner = Gitleaks::Scanner.new
      results = scanner.scan("DB_PASSWORD=m9kP2xW8nL5vQ8r")
      results.should_not be_empty
      results.any? { |res| res.rule_id == "env-secret" }.should be_true
    end

    it "should detect a generic password assignment" do
      scanner = Gitleaks::Scanner.new
      results = scanner.scan("password = SuperSecret123!")
      results.should_not be_empty
      results.any? { |res| res.rule_id == "generic-password" }.should be_true
    end

    it "should detect multiple secrets in one text" do
      scanner = Gitleaks::Scanner.new
      text = <<-TEXT
      STRIPE_KEY=sk_live_4eC39HqLyjWDarjtT1zdp7dc
      GITLAB_PAT=glpat-ABCDEFGHIJKLMNOPQRST
      postgres://admin:s3cRetP4ss@db.example.com:5432/myapp
      TEXT
      results = scanner.scan(text)
      results.size.should be >= 3
    end

    it "should populate result fields" do
      scanner = Gitleaks::Scanner.new
      results = scanner.scan("STRIPE_KEY=sk_live_4eC39HqLyjWDarjtT1zdp7dc")
      results.should_not be_empty

      result = results.first
      result.rule_id.should_not be_empty
      result.description.should_not be_empty
      result.secret.should_not be_empty
      result.match.should_not be_empty
    end
  end
end
