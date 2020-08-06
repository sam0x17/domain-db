require "myhtml"
require "http/client"
require "log"

module DomainDB
  Log = ::Log.for("DomainDB")
  # contains the TLD database as a set of top level domain extensions
  # (com, net, etc.)
  #
  # `#update_tlds` must be called before this set will be populated
  class_getter tld_extensions : Set(String) = Set(String).new

  # contains the public suffix database from mozilla as a set
  # of registerable domain extensions (com, com.mx, etc.). This
  # set is a super set of `#tld_extensions` and all registerable
  # domain names.
  #
  # `#update_suffixes` must be called before this set will be populated
  class_getter suffixes : Set(String) = Set(String).new

  # see `#update_tlds` or `#update_suffixes`
  class_property retry_count : Int32 = 5

  # see `#update_tlds` or `#update_suffixes`
  class_property backoff_time : Time::Span = 0.2.seconds

  # see `#update_tlds` or `#update_suffixes`
  class_property backoff_factor : Float64 = 1.5

  # the URL for the IANA TLD extensions list
  TLD_URL = "https://www.iana.org/domains/root/db"

  # the url for the mozilla public suffixes list
  SUFFIX_URL = "https://publicsuffix.org/list/public_suffix_list.dat"

  # updates the tld extensions database by downloading and parsing html from `#TLD_URL`. Upon
  # a failure (non-200 status code) exponential backoff will be used until `retry_count` is reached.
  #
  # arguments:
  # `retry_count` (optional): specifies maximum number of retries before raising
  # `backoff_time` (optional): initial amount of time we should wait before trying again upon a failure
  # `backoff_factor` (optional): `backoff_time` is multiplied by this factor on each failure. Should be greater than 1
  def self.update_tlds(retry_count : Int32 = self.retry_count, backoff_time : Time::Span = self.backoff_time, backoff_factor : Float64 = self.backoff_factor)
    Log.info { "downloading TLD database from IANA..." }
    response = HTTP::Client.get(TLD_URL)
    if response.status_code != 200
      if retry_count > 0
        Log.warn { "#{TLD_URL} returned a non-200 status code (#{response.status_code}), retrying in #{backoff_time.total_seconds}s" }
        sleep backoff_time
        return self.update_tlds(retry_count - 1, backoff_time * backoff_factor)
      end
      raise "could not access #{TLD_URL} after several retries, status_code: #{response.status_code}"
    end
    myhtml = Myhtml::Parser.new(response.body)
    @@tld_extensions = myhtml.css("span.domain.tld > a").map(&.inner_text[1..]).to_set
    Log.info { "successfully loaded #{self.tld_extensions.size} top level domain extensions from IANA" }
  end

  # updates the mozilla public suffixes database by downloading and parsing data from `#SUFFIX_URL`. Upon
  # a failure (non-200 status code) exponential backoff will be used until `retry_count` is reached.
  #
  # arguments:
  # `retry_count` (optional): specifies maximum number of retries before raising
  # `backoff_time` (optional): initial amount of time we should wait before trying again upon a failure
  # `backoff_factor` (optional): `backoff_time` is multiplied by this factor on each failure. Should be greater than 1
  def self.update_suffixes(retry_count : Int32 = self.retry_count, backoff_time : Time::Span = self.backoff_time, backoff_factor : Float64 = self.backoff_factor)
    Log.info { "downloading public suffixes database from mozilla..." }
    response = HTTP::Client.get(SUFFIX_URL)
    if response.status_code != 200
      if retry_count > 0
        Log.warn { "#{SUFFIX_URL} returned a non-200 status code (#{response.status_code}), retrying in #{backoff_time.total_seconds}s" }
        sleep backoff_time
        return self.update_suffixes(retry_count - 1, backoff_time * backoff_factor)
      end
      raise "could not access #{SUFFIX_URL} after several retries, status_code: #{response.status_code}"
    end
    @@suffixes = response.body.lines.map(&.strip).reject { |line| line.starts_with?("/") || line.empty? }
      .map { |ext| ext.starts_with?("*") ? ext[1..] : ext }.to_set
    Log.info { "successfully loaded #{self.suffixes.size} domain suffixes from mozilla" }
  end

  # extracts the domain name from `hostname` using the public
  # suffixes database to identify the portion of hostname that
  # is a public suffix. The next token to the left is returned
  # (with its suffix) as the domain name. This effectively strips
  # subdomains from an arbitrary domain name. If `tld_only` is
  # set to `true`, only top-level domains according to IANA
  # will be used (meaning "co.uk" would be the detected domain
  # for hostanmes like `site.co.uk`). By default the mozilla
  # public suffixes database is used.
  def self.strip_subdomains(hostname : String, tld_only = false) : String
    set = tld_only ? self.tld_extensions : self.suffixes
    (tld_only ? self.update_tlds : self.update_suffixes) if set.empty?
    tokens = hostname.downcase.split(".")
    (0..(tokens.size - 1)).each do |i|
      extension = tokens[i..].join(".")
      return tokens[(i-1)..].join(".") if self.suffixes.includes?(extension)
    end
    return hostname.downcase
  end

  # removes the domain extension / suffix from the end of the specified
  # hostname. Follows the same options and semantics as `#strip_subdomains`.
  def self.strip_suffix(hostname : String, tld_only = false) : String
    set = tld_only ? self.tld_extensions : self.suffixes
    (tld_only ? self.update_tlds : self.update_suffixes) if set.empty?
    tokens = hostname.downcase.split(".")
    (0..(tokens.size - 1)).each do |i|
      extension = tokens[i..].join(".")
      return tokens[0..(i - 1)].join(".") if self.suffixes.includes?(extension)
    end
    return hostname.downcase
  end
end
