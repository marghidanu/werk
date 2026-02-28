require "../spec_helper"

describe ShellCheck::Scanner do
  describe ".shell_name" do
    it "returns dialect for absolute path" do
      ShellCheck::Scanner.shell_name("/bin/bash").should eq "bash"
      ShellCheck::Scanner.shell_name("/bin/sh").should eq "sh"
      ShellCheck::Scanner.shell_name("/bin/ash").should eq "sh"
    end

    it "returns dialect for env-style interpreter" do
      ShellCheck::Scanner.shell_name("/usr/bin/env bash").should eq "bash"
      ShellCheck::Scanner.shell_name("/usr/bin/env busybox").should eq "sh"
    end

    it "returns dialect for bare command" do
      ShellCheck::Scanner.shell_name("bash").should eq "bash"
      ShellCheck::Scanner.shell_name("dash").should eq "dash"
      ShellCheck::Scanner.shell_name("ksh").should eq "ksh"
      ShellCheck::Scanner.shell_name("ash").should eq "sh"
    end

    it "returns nil for unsupported interpreters" do
      ShellCheck::Scanner.shell_name("python").should be_nil
      ShellCheck::Scanner.shell_name("/usr/bin/ruby").should be_nil
      ShellCheck::Scanner.shell_name("/usr/bin/env node").should be_nil
      ShellCheck::Scanner.shell_name("zsh").should be_nil
    end
  end

  describe "#scan" do
    it "detects issues in a bad script" do
      scanner = ShellCheck::Scanner.new
      findings = scanner.scan("x=1", "sh")

      findings.should_not be_empty
      findings.first.code.should eq 2034
      findings.first.level.should eq "warning"
      findings.first.message.should contain "unused"
    end

    it "returns empty for a clean script" do
      scanner = ShellCheck::Scanner.new
      findings = scanner.scan("echo hello", "sh")

      findings.should be_empty
    end
  end
end

describe ShellCheck::Finding do
  it "deserializes from JSON" do
    json = %({
      "file": "-",
      "line": 1,
      "endLine": 1,
      "column": 1,
      "endColumn": 2,
      "level": "warning",
      "code": 2034,
      "message": "x appears unused."
    })

    finding = ShellCheck::Finding.from_json(json)
    finding.file.should eq "-"
    finding.line.should eq 1
    finding.end_line.should eq 1
    finding.column.should eq 1
    finding.end_column.should eq 2
    finding.level.should eq "warning"
    finding.code.should eq 2034
    finding.message.should eq "x appears unused."
  end
end
