require "../spec_helper"

describe Werk::Utils::PrefixIO do
  it "should prefix each line with the job name" do
    output = IO::Memory.new
    io = Werk::Utils::PrefixIO.new(output, "test")
    Werk::Utils::PrefixIO.enabled = true

    io.print("hello\n")
    io.close

    output.to_s.should contain("[test]")
    output.to_s.should contain("hello")
  end

  it "should buffer partial writes until newline" do
    output = IO::Memory.new
    io = Werk::Utils::PrefixIO.new(output, "test")
    Werk::Utils::PrefixIO.enabled = true

    io.print("hel")
    output.to_s.should eq("")

    io.print("lo\n")
    output.to_s.should contain("hello")
    io.close
  end

  it "should flush remaining buffer on close" do
    output = IO::Memory.new
    io = Werk::Utils::PrefixIO.new(output, "test")
    Werk::Utils::PrefixIO.enabled = true

    io.print("no newline")
    output.to_s.should eq("")

    io.close
    output.to_s.should contain("no newline")
  end

  it "should suppress output when disabled" do
    output = IO::Memory.new
    io = Werk::Utils::PrefixIO.new(output, "test")
    Werk::Utils::PrefixIO.enabled = false

    io.print("hidden\n")
    io.close

    output.to_s.should eq("")
  ensure
    Werk::Utils::PrefixIO.enabled = true
  end

  it "should strip cursor movement ANSI codes" do
    output = IO::Memory.new
    io = Werk::Utils::PrefixIO.new(output, "test")
    Werk::Utils::PrefixIO.enabled = true

    io.print("\033[2Ahello\n")
    io.close

    output.to_s.should contain("hello")
    output.to_s.should_not contain("\033[2A")
  end

  it "should preserve color ANSI codes" do
    output = IO::Memory.new
    io = Werk::Utils::PrefixIO.new(output, "test")
    Werk::Utils::PrefixIO.enabled = true

    io.print("\033[31mred text\033[0m\n")
    io.close

    output.to_s.should contain("\033[31m")
  end

  it "should convert carriage returns to newlines" do
    output = IO::Memory.new
    io = Werk::Utils::PrefixIO.new(output, "test")
    Werk::Utils::PrefixIO.enabled = true

    io.print("line1\rline2\n")
    io.close

    # \r becomes \n, so "line1" flushes as its own line
    output.to_s.should contain("line1")
    output.to_s.should contain("line2")
  end

  it "should handle multiple lines in a single write" do
    output = IO::Memory.new
    io = Werk::Utils::PrefixIO.new(output, "test")
    Werk::Utils::PrefixIO.enabled = true

    io.print("line1\nline2\nline3\n")
    io.close

    output.to_s.scan(/\[test\]/).size.should eq(3)
  end

  it "should handle broken pipe gracefully" do
    # Use a closed IO to simulate a broken pipe (raises IO::Error on write)
    broken_output = IO::Memory.new
    broken_output.close

    io = Werk::Utils::PrefixIO.new(broken_output, "test")
    Werk::Utils::PrefixIO.enabled = true

    # Writing to a closed IO should not raise
    io.print("this will break\n")
    io.close
  end

  it "should raise on read" do
    output = IO::Memory.new
    io = Werk::Utils::PrefixIO.new(output, "test")

    expect_raises(IO::Error, "Can't read from this IO!") do
      io.read(Bytes.new(1))
    end
    io.close
  end
end
