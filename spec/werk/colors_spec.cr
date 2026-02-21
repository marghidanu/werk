require "../spec_helper"

describe "Colors" do
  it "should return circular values" do
    colors = Werk::Utils::Colors.new
    first_color = colors.next_color

    (Werk::Utils::Colors::PALETTE.size - 1).times do
      colors.next_color
    end

    colors.next_color.should eq first_color
  end
end
