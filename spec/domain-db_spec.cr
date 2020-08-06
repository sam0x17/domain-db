require "./spec_helper"

describe DomainDB do
  # TODO: Write tests

  it "updates TLD list correctly" do
    DomainDB.update_tlds
    extensions = DomainDB.tld_extensions
    (extensions.size > 100).should eq true
    extensions.includes?("com").should eq true
    extensions.includes?("actor").should eq true
    extensions.includes?("io").should eq true
    extensions.includes?("com.mx").should eq false # these aren't top-level
  end
end
