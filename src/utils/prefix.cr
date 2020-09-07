require "colorize"

module Werk::Utils
  class PrefixIO < IO
    # Creates a new instance that will use output to write to
    def initialize(@output : IO, @prefix : String)
    end

    # Does nothing, reading is disabled for this IO
    def read(slice : Bytes)
      raise IO::Error.new("Can't read from this IO!")
    end

    # Adds a defined stamp for each incoming line
    def write(slice : Bytes) : Nil
      return if slice.empty?

      data = String.new(slice)
      data.each_line do |line|
        @output.puts "[#{@prefix}] #{line}"
      end

      nil
    end
  end
end
