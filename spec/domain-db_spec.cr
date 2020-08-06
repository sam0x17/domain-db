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

  it "updates suffixes list correctly" do
    DomainDB.update_suffixes
    suffixes = DomainDB.suffixes
    (suffixes.size > 1000).should eq true
    suffixes.includes?("com.mx").should eq true
    suffixes.includes?("com").should eq true
    suffixes.includes?("co.uk").should eq true
    suffixes.includes?("academy").should eq true
    suffixes.includes?("ninja").should eq true
  end

  # there are 125 that don't meet this criteria, leaving alone for now
  pending "ensures that tld list is a subset of suffixes list" do
    DomainDB.update_suffixes if DomainDB.suffixes.empty?
    DomainDB.update_tlds if DomainDB.tld_extensions.empty?
    suffixes = DomainDB.suffixes
    extensions = DomainDB.tld_extensions
    pp! (extensions - suffixes)
    (extensions - suffixes).size.should eq 0
  end
end
