module Gitleaks
  # Embedded gitleaks config with custom rules that extend the defaults.
  BUILTIN_RULES = <<-TOML
    [extend]
    useDefault = true

    [[rules]]
    id = "database-connection-url"
    description = "Detected a database connection URL with embedded credentials."
    regex = '''(?i)(?:postgres(?:ql)?|mysql|mongodb(?:\\+srv)?|redis|amqp|mssql):\\/\\/[^:\\s]+:([^@\\s]+)@[^\\s]+'''
    keywords = ["postgres", "postgresql", "mysql", "mongodb", "redis", "amqp", "mssql"]

    [[rules]]
    id = "generic-password"
    description = "Generic password assignment."
    regex = '''(?i)\\b(pass(word|phrase)?|passwd)\\b\\s*[:=]\\s*["'']?([a-zA-Z0-9!@#$%^&*()_+={}\\[\\]:;<>,.?\\/\\\\|~-]{6,})["'']?'''
    secretGroup = 3
    keywords = ["password", "passwd", "passphrase"]

    [[rules]]
    id = "env-secret"
    description = "Environment variable style secret."
    regex = '''\\b[A-Z0-9_]+_?(PASS|PASSWORD|SECRET|TOKEN)[A-Z0-9_]*\\b\\s*[:=]\\s*["'']?([A-Za-z0-9!@#$%^&*()_+={}\\[\\]:;<>,.?\\/\\\\|~-]{6,})["'']?'''
    secretGroup = 2
    keywords = ["PASS", "PASSWORD", "SECRET", "TOKEN"]

    [[rules]]
    id = "jwt-token"
    description = "JWT token."
    regex = '''(eyJ[a-zA-Z0-9\\-_]+\\.[a-zA-Z0-9\\-_]+\\.[a-zA-Z0-9\\-_]+)'''
    keywords = ["eyJ"]
    TOML
end
