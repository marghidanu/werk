require "colorize"

require "./colors"

module Werk
  class Utils::PrefixIO < IO
    @color : Colorize::Color

    # Creates a new instance that will use output to write to
    def initialize(@output : IO, @prefix : String)
      @color = Werk::Utils::Colors.instance.next_color
      @new_line = true
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
        .gsub(/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]/, "")
        .gsub("\r", "\n")

      data.each_char do |char|
        @output.print("[#{@prefix.colorize(@color)}] ") if @new_line
        @output.print(char)
        @new_line = (char == '\n')
      end
    rescue ex : IO::Error
      # TODO: This is a known issue with piping
      nil
    end
  end
end
