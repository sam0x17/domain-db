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
    extensions.includes?("com.mx").should eq false # not top level
    extensions.includes?("co.uk").should eq false # not top level
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

  describe "#strip_subdomains" do
    it "works on standard top level domains" do
      DomainDB.strip_subdomains("sam0x17.dev").should eq "sam0x17.dev"
      DomainDB.strip_subdomains("OMG-LOL.net").should eq "omg-lol.net"
      DomainDB.strip_subdomains("forum.durosoft.com").should eq "durosoft.com"
      DomainDB.strip_subdomains("resume.sam0x17.dev").should eq "sam0x17.dev"
      DomainDB.strip_subdomains("co.uk.some-cool.thing-ok.example.com").should eq "example.com"
    end

    it "works on fancy compound domains" do
      DomainDB.strip_subdomains("awesome-site.bro.co.uk").should eq "bro.co.uk"
      DomainDB.strip_subdomains("my.fancy-blog.com.mx").should eq "fancy-blog.com.mx"
    end

    it "leaves unrecognized extensions unchanged" do
      DomainDB.strip_subdomains("sub.dOmain.nonexistentextension").should eq "sub.domain.nonexistentextension"
    end
  end

  describe "#strip_suffix" do
    it "handles a variety of hostnames" do
      DomainDB.strip_suffix("whatever-ok.my-blog.ok.yeah.yuh.co.uk").should eq "whatever-ok.my-blog.ok.yeah.yuh"
      DomainDB.strip_suffix("sAm0x17.dev").should eq "sam0x17"
      DomainDB.strip_suffix("mywebsite.com.mx").should eq "mywebsite"
    end

    it "leaves unrecognized extensions unchanged" do
      DomainDB.strip_suffix("sub.domain.nOnexistentextension").should eq "sub.domain.nonexistentextension"
    end
  end
end
