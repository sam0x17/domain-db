require "myhtml"
require "http/client"
require "log"

module TLD::DB
  Log = ::Log.for("tld:db")
  # contains the TLD database as a set of top level domain extensions
  # `#.update` must be called before this set will be populated
  class_getter extensions : Set(String) = Set(String).new

  # see `#update`
  class_property retry_count : Int32 = 5

  # see `#update`
  class_property backoff_time : Time::Span = 0.2.seconds

  # see `#update`
  class_property backoff_factor : Float64 = 1.5

  # the URL for the IANA TLD extensions list
  DB_URL = "https://www.iana.org/domains/root/db"

  # updates the extension database by downloading and parsing html from `#DB_URL`. Upon
  # a failure (non-200 status code) exponential backoff will be used until
  # `retry_count` is reached.
  #
  # arguments:
  # `retry_count` (optional): specifies maximum number of retries before raising
  # `backoff_time` (optional): initial amount of time we should wait before trying again upon a failure
  # `backoff_factor` (optional): `backoff_time` is multiplied by this factor on each failure. Should be greater than 1
  def self.update(retry_count : Int32 = self.retry_count, backoff_time : Time::Span = self.backoff_time, backoff_factor : Float64 = self.backoff_factor)
    Log.info { "downloading TLD database from IANA..." }
    response = HTTP::Client.get(DB_URL)
    if response.status_code != 200
      if retry_count > 0
        Log.warn { "#{DB_URL} returned a non-200 status code (#{response.status_code}), retrying in #{backoff_time.total_seconds}s" }
        sleep backoff_time
        return self.update(retry_count - 1, backoff_time * backoff_factor)
      end
      raise "could not access #{DB_URL} after several retries, status_code: #{response.status_code}"
    end
    myhtml = Myhtml::Parser.new(response.body)
    @@extensions = myhtml.css("span.domain.tld > a").map(&.inner_text[1..]).to_set
    Log.info { "successfully loaded #{self.extensions.size} TLDs from IANA" }
  end
end
