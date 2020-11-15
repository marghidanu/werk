require "colorize"

module Werk::Utils
  class Colors
    getter colors = [91, 92, 93, 94, 95, 96, 31, 32, 33, 34, 35, 36, 37, 90]

    def initialize
      @index = 0
    end

    def next_color : Colorize::Color
      @index = 0 if @index >= @colors.size
      color = Colorize::ColorANSI.new(@colors[@index])
      @index += 1

      color
    end

    def self.instance
      @@instance ||= new
    end
  end
end
