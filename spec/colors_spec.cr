require "./spec_helper"

describe "Colors" do
  it "should return circular values" do
    colors = Werk::Utils::Colors.new
    color = colors.next_color

    (colors.colors.size - 2).times do
      colors.next_color
    end

    color.to_u8.should eq 91
  end
end
