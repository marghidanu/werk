require "colorize"

module Werk::Utils
  class Colors
    getter colors = [
      Colorize::ColorANSI::LightRed,
      Colorize::ColorANSI::LightGreen,
      Colorize::ColorANSI::LightYellow,
      Colorize::ColorANSI::LightBlue,
      Colorize::ColorANSI::LightMagenta,
      Colorize::ColorANSI::LightCyan,
      Colorize::ColorANSI::Red,
      Colorize::ColorANSI::Green,
      Colorize::ColorANSI::Yellow,
      Colorize::ColorANSI::Blue,
      Colorize::ColorANSI::Magenta,
      Colorize::ColorANSI::Cyan,
      Colorize::ColorANSI::LightGray,
      Colorize::ColorANSI::DarkGray,
    ]

    def initialize
      @index = 0
    end

    def next_color : Colorize::Color
      @index = 0 if @index >= @colors.size
      color = @colors[@index]
      @index += 1

      color
    end

    def self.instance
      @@instance ||= new
    end
  end
end
