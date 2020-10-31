module Werk::Utils
  class Term
    def self.clear_screen
      print "\33c\e[3J"
    end
  end
end
