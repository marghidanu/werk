module Werk::Utils
  module Colors
    # Generated from the 6×6×6 color cube (codes 16–231).
    # Filtered for visibility on dark and light terminals:
    # brightness (r+g+b) in [4, 11], saturation (max-min) >= 2
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

      # Reorder with maximum spacing: stride by golden-ratio step
      # (coprime with n) so consecutive picks are perceptually far apart.
      n = colors.size
      step = (n * 0.618).to_i.clamp(1, n - 1)
      while n.gcd(step) != 1
        step += 1
      end

      spaced = Array(Colorize::Color256).new(n)
      idx = 0
      n.times do
        spaced << colors[idx]
        idx = (idx + step) % n
      end

      spaced
    end

    @@index = 0

    def self.next_color : Colorize::Color
      @@index = 0 if @@index >= PALETTE.size
      color = PALETTE[@@index]
      @@index += 1

      color
    end
  end
end
