module Werk::Utils
  class Colors
    # Generated from the 6×6×6 color cube (codes 16–231).
    # Filtered for visibility on dark and light terminals:
    #   brightness (r+g+b) in [4, 11], saturation (max-min) >= 2
    PALETTE = begin
      colors = Array(Colorize::Color256).new
      6.times do |red|
        6.times do |green|
          6.times do |blue|
            brightness = red + green + blue
            saturation = [red, green, blue].max - [red, green, blue].min
            next if brightness < 4 || brightness > 11 || saturation < 2

            colors << Colorize::Color256.new((16 + 36 * red + 6 * green + blue).to_u8)
          end
        end
      end

      colors.shuffle(Random.new(42))
    end

    def initialize
      @index = 0
    end

    def next_color : Colorize::Color
      @index = 0 if @index >= PALETTE.size
      color = PALETTE[@index]
      @index += 1

      color
    end

    def self.instance
      @@instance ||= new
    end
  end
end
