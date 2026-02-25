module Werk::Utils
  class PrefixIO < IO
    ANSI_RESET = "\033[0m"

    # Strip cursor movement/positioning, but keep color (SGR) codes
    ANSI_STRIP = /\x1B\[[0-9;]*[A-HJ-K]/

    class_property? enabled : Bool = true
    @@mutex = Mutex.new

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

    private def flush_line
      @@mutex.synchronize do
        @output.print("#{ANSI_RESET}[#{@prefix.colorize(@color)}] #{@buffer}")
      end
      @buffer = ""
    end
  end
end
