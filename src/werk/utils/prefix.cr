module Werk::Utils
  class PrefixIO < IO
    ANSI_RESET = "\033[0m"

    # Strip cursor movement/positioning, but keep color (SGR) codes
    ANSI_STRIP = /\x1B\[[0-9;]*[A-HJ-K]/

    class_property? enabled : Bool = true

    @color : Colorize::Color
    @buffer : String = ""

    def initialize(@output : IO, @prefix : String)
      @color = Werk::Utils::Colors.next_color
    end

    def read(slice : Bytes)
      raise IO::Error.new("Can't read from this IO!")
    end

    def write(slice : Bytes) : Nil
      check_open

      return unless self.class.enabled?
      return if slice.empty?

      data = String.new(slice)
        .gsub(ANSI_STRIP, "")
        .gsub("\r", "\n")

      data.each_line(chomp: false) do |line|
        @buffer += line
        if @buffer.ends_with?('\n')
          flush_line
        end
      end
    rescue ex : IO::Error
      nil
    end

    # Flush any remaining partial line (e.g. when the process exits)
    def close : Nil
      flush_line unless @buffer.empty?
      super
    end

    # Silently discard on broken pipe (e.g. piped output closed early).
    private def flush_line
      return @buffer = "" if @output.closed?

      # Use `write` instead of `print` — Crystal has a bug where exceptions
      # raised through the IO#print → String#to_s → IO#write_string chain
      # bypass rescue handlers entirely.
      msg = "#{ANSI_RESET}[#{@prefix.colorize(@color)}] #{@buffer}"
      @output.write(msg.to_slice)
      @buffer = ""
    rescue IO::Error
      @buffer = ""
    end
  end
end
