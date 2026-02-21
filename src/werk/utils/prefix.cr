module Werk::Utils
  class PrefixIO < IO
    ANSI_RESET = "\033[0m"

    class_property? enabled : Bool = true
    @@mutex = Mutex.new

    @color : Colorize::Color
    @new_line : Bool = true

    def initialize(@output : IO, @prefix : String)
      @color = Werk::Utils::Colors.instance.next_color
    end

    def read(slice : Bytes)
      raise IO::Error.new("Can't read from this IO!")
    end

    def write(slice : Bytes) : Nil
      check_open

      return unless self.class.enabled?
      return if slice.empty?

      @@mutex.synchronize do
        data = String.new(slice)
          .gsub(/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]/, "")
          .gsub("\r", "\n")

        data.each_char do |char|
          @output.print("[#{@prefix.colorize(@color)}] ") if @new_line
          @output.print(char)
          @new_line = (char == '\n')
        end
      end
    rescue ex : IO::Error
      nil
    end
  end
end
