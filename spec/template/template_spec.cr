require "../spec_helper"

describe Template::Interpolation do
  describe "#interpolate" do
    it "should return plain text unchanged" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("hello world")
      result.should eq "hello world"
    end

    it "should handle empty string" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("")
      result.should eq ""
    end

    it "should interpolate a single variable" do
      result = Template::Interpolation.new.expand({"TAG" => "v1.2.3"}).interpolate("image: ${TAG}")
      result.should eq "image: v1.2.3"
    end

    it "should interpolate multiple variables" do
      result = Template::Interpolation.new.expand({"REPO" => "myapp", "TAG" => "latest"}).interpolate("${REPO}:${TAG}")
      result.should eq "myapp:latest"
    end

    it "should leave undefined variables as-is" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("${UNDEFINED}")
      result.should eq "${UNDEFINED}"
    end

    it "should handle a lone dollar sign" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("cost is $5")
      result.should eq "cost is $5"
    end

    it "should not expand bare $VAR syntax" do
      result = Template::Interpolation.new.expand({"VAR" => "x"}).interpolate("$VAR")
      result.should eq "$VAR"
    end

    it "should handle underscored variable names" do
      result = Template::Interpolation.new.expand({"MY_VAR_123" => "val"}).interpolate("${MY_VAR_123}")
      result.should eq "val"
    end

    it "should handle adjacent interpolations" do
      result = Template::Interpolation.new.expand({"A" => "x", "B" => "y"}).interpolate("${A}${B}")
      result.should eq "xy"
    end

    it "should handle malformed template gracefully" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("${UNCLOSED")
      result.should eq "${UNCLOSED"
    end

    it "should handle empty braces as literal" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("${}")
      result.should eq "${}"
    end

    it "should handle digit-leading name as literal" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("${123}")
      result.should eq "${123}"
    end

    it "should handle nested braces as literal" do
      result = Template::Interpolation.new.expand({"X" => "val"}).interpolate("${${X}}")
      result.should eq "${val}"
    end

    it "should handle $ at end of string" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("end$")
      result.should eq "end$"
    end

    it "should escape $$ to a single $" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("price is $$5")
      result.should eq "price is $5"
    end

    it "should use $$ to prevent variable expansion" do
      result = Template::Interpolation.new.expand({"VAR" => "expanded"}).interpolate("$${VAR}")
      result.should eq "${VAR}"
    end

    it "should handle $$ at end of string" do
      result = Template::Interpolation.new.expand({} of String => String).interpolate("end$$")
      result.should eq "end$"
    end
  end

  describe "#interpolate_all" do
    it "should render each element" do
      result = Template::Interpolation.new.expand({"A" => "1", "B" => "2"}).interpolate_all(
        ["${A}", "literal", "${B}"]
      )
      result.should eq ["1", "literal", "2"]
    end
  end
end
