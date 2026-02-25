require "../spec_helper"

describe "Colors" do
  it "should have a reasonable palette size" do
    Werk::Utils::Colors::PALETTE.size.should be > 20
  end

  it "should have no duplicate colors in palette" do
    palette = Werk::Utils::Colors::PALETTE
    palette.uniq.size.should eq palette.size
  end

  it "should return circular values" do
    first_color = Werk::Utils::Colors.next_color

    (Werk::Utils::Colors::PALETTE.size - 1).times do
      Werk::Utils::Colors.next_color
    end

    Werk::Utils::Colors.next_color.should eq first_color
  end

  it "should return different colors for consecutive calls" do
    a = Werk::Utils::Colors.next_color
    b = Werk::Utils::Colors.next_color
    a.should_not eq b
  end
end
