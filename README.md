# DomainDB

Contains a dynamically updated database of top level domain extensions (from IANA)
and the public suffixes list from Mozilla.

## Usage

```crystal
require "domain-db"

# suffix list contains everything
DomainDB.update_suffixes
DomainDB.suffixes.includes?("com.mx").should eq true
DomainDB.suffixes.includes?("net").should eq true
DomainDB.tld_extensions.includes?("ninja").should eq true

# tld list just contains top level domains according to IANA
DomainDB.update_tlds
DomainDB.tld_extensions.includes?("com.mx").should eq false # not top level
DomainDB.tld_extensions.includes?("net").should eq true
DomainDB.tld_extensions.includes?("ninja").should eq true
DomainDB.tld_extensions.includes?("co.uk").should eq false # not top level
```

Also see specs for usage for `DomainDB.strip_subdomains` and `DomainDB.strip_suffix`.

## Installation

Add the following to your `shards.yml` file:
```yaml
dependencies:
  domain-db:
    github: sam0x17/domain-db
```
