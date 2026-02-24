require "../spec_helper"

describe "Colors" do
  it "should return circular values" do
    first_color = Werk::Utils::Colors.next_color

    (Werk::Utils::Colors::PALETTE.size - 1).times do
      Werk::Utils::Colors.next_color
    end

    Werk::Utils::Colors.next_color.should eq first_color
  end
end
