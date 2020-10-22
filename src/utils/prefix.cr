require "colorize"

require "./colors"

module Werk::Utils
  class PrefixIO < IO
    @color : Colorize::Color

    # Creates a new instance that will use output to write to
    def initialize(@output : IO, @prefix : String)
      @color = Werk::Utils::Colors.instance.next_color
    end

    # Does nothing, reading is disabled for this IO
    def read(slice : Bytes)
      raise IO::Error.new("Can't read from this IO!")
    end

    # Adds a defined stamp for each incoming line
    def write(slice : Bytes) : Nil
      check_open

      return if slice.empty?

      data = String.new(slice)
      data.gsub("\r", "\n").each_line do |line|
        @output.puts "[#{@prefix.colorize(@color)}]\t#{line.gsub(/\e\[([;\d]+)?m/, "").strip()}"
      end
    rescue ex : IO::Error
      # TODO: This is a known issue with piping
      nil
    end
  end
end
