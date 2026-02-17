# frozen_string_literal: true

# UrlShortener is a simple Rack app for shortening URLs.
# It should work with any Rack app and database.
# URLs are always of the form "<root>/<id>",
# and the ID is assumed to always be the last section of the request path.
class UrlShortener
  # When inserting unique IDs for shortened URLs, attempt to upsert this many times before
  # giving up and raising +NoIdAvailable+. This happens when there are few available IDs
  # for the given byte size.
  MAX_UNIQUE_ID_ATTEMPTS = 5

  class NoIdAvailable < StandardError; end

  class << self
    # Generate a new short id.
    # The first 4 bytes (usually six characters) is the current second,
    # the last +byte_size+ bytes are random.
    # See +byte_size+ for more info.
    def gen_short_id(byte_size)
      # Encode numbers with a radix is 36, which gives us many available characters to encode with.
      # For example, `414.to_s(16)` would hex encode.
      epoch_second_encoded = Time.now.to_i.to_s(36)
      # Encode random bytes as hex, then parse it as an integer,
      # so we can encode the integer with a radix 36.
      rand_part_hex = Digest.hexencode(SecureRandom.bytes(byte_size)).to_i(16).to_s(36)
      return epoch_second_encoded + rand_part_hex
    end
  end

  # Sequel database connection to the database hosting the shortener table.
  # @type [Sequel::Connection]
  attr_accessor :conn

  # Name of the Sequel table, or a Sequel expression to the table.
  # Default to +:url_shortener+.
  # @type [Symbol,Sequel::SQL::Expression]
  attr_accessor :table

  # Root URL for redirect urls, to which the generated ID is appended.
  # For example, a +root+ of "https://example.org/abc" would produce
  # shortened URLs from +shortened_url+ like "https://example.org/abc/1cad243fo".
  # Usually this would be the URL of the application and path hosting the +UrlShortener::RackApp+ app.
  # @type [String]
  attr_accessor :root

  # When a short ID cannot be resolved, the middleware will redirect to this URL.
  # Defaults to the path "/404".
  # @type [String]
  attr_accessor :not_found_url

  # Size of the random part of the ID.
  # The first, time-based portion of the ID changes each second, and is encoded 4 bytes (usually 6 characters).
  # The second, random part of the ID, is encoded as another <byte_size> bytes,
  # by default 2 bytes (usually 3 characters).
  # This allows at least a few thousand URLs every second
  # (you would never hit the 65k URLs/second because of randomness conflicts).
  # This yields, by default, a total ID length of 9 characters.
  # @type [Integer]
  attr_accessor :byte_size

  def initialize(conn:, root:, table: :url_shortener, not_found_url: "/404", byte_size: 2)
    @conn = conn
    @table = table
    @root = root
    @not_found_url = not_found_url
    @byte_size = byte_size
  end

  # @return [Sequel::Dataset]
  def dataset = @conn[@table]

  Shortened = Struct.new(:id, :short_id, :short_url, :long_url, :inserted_at)

  # @return [Shortened]
  def shortened_from_row(row)
    short_id = row.fetch(:short_id)
    return Shortened.new(
      row.fetch(:id),
      short_id,
      self.short_url_from_id(short_id),
      row.fetch(:url),
      row.fetch(:inserted_at),
    )
  end

  def short_url_from_id(short_id) = "#{@root}/#{short_id}"

  def gen_short_id = self.class.gen_short_id(@byte_size)

  # Return the short ID and shortened URL pointing to the full url.
  # @param [String] url
  # @return [Shortened]
  def shorten(url, now: nil)
    (MAX_UNIQUE_ID_ATTEMPTS - 1).times do
      short_id = self.gen_short_id
      vals = {url:, short_id:}
      vals[:inserted_at] = now if now
      row = @conn[@table].returning.insert(vals).first
      return self.shortened_from_row(row)
    rescue Sequel::UniqueConstraintViolation
      nil
    end
    msg = "Could not generate a valid short_id after #{MAX_UNIQUE_ID_ATTEMPTS} attempts, " \
          "you are probably at or approaching the maximum number of shortened IDs for #{@bytesize} bytes. " \
          "You should increase the :bytesize value."
    raise NoIdAvailable, msg
  end

  def update(row_id, short_id: nil, url: nil, now: Time.now)
    params = {}
    unless short_id.nil?
      short_id = short_id.strip
      short_id = self.class.gen_short_id(@byte_size) if short_id.blank?
      params[:short_id] = short_id
    end
    params[:url] = url.strip unless url.nil?
    params[:inserted_at] = now
    row = @conn[@table].
      where(id: row_id).
      returning.
      update(params).
      first
    return shortened_from_row(row)
  end

  # Given a shortened ID (tail of the URL),
  # return the URL, or nil.
  # @param [String,nil] short_id
  # @return [String,nil]
  def resolve_short_id(short_id)
    row = @conn[@table].where(short_id:).select(:url).first
    return nil if row.nil?
    return row[:url]
  end

  # Given a short URL, return the full URL, or nil.
  # @param [String,URI::Generic] url
  # @return [String,nil]
  def resolve_short_url(url)
    uri = url.is_a?(URI) ? url : URI(url)
    return self.resolve_short_id(uri.path.delete_suffix("/").split("/").last)
  end
end
