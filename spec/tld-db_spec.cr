require "./spec_helper"

describe TLD::DB do
  # TODO: Write tests

  it "updates correctly" do
    TLD::DB.update
    extensions = TLD::DB.extensions
    (extensions.size > 100).should eq true
    extensions.includes?("com").should eq true
    extensions.includes?("actor").should eq true
    extensions.includes?("io").should eq true
    extensions.includes?("com.mx").should eq false # these aren't top-level
  end
end
