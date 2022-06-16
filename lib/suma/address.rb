# frozen_string_literal: true

require "appydays/configurable"
require "geokit"
require "appydays/loggable"

require "suma/postgres/model"

class Suma::Address < Suma::Postgres::Model(:addresses)
  include Appydays::Configurable
  include Appydays::Loggable
  extend Suma::MethodUtilities

  many_to_many :member, class: "Suma::Member"

  # The default country code for new addresses
  DEFAULT_COUNTRY = "US"

  Geokit.include(Appydays::Loggable)

  # The geocoder class to use
  singleton_attr_accessor :geocoder

  configurable(:geocoders) do
    setting :geocoder_name, "google"
    setting :google_api_key, "fake-google-key"
    setting :mapbox_api_key, "fake-mapbox-key"

    after_configured do
      Geokit::Geocoders::GoogleGeocoder.api_key = self.google_api_key
      Geokit::Geocoders::MapboxGeocoder.key = self.mapbox_api_key
      geo_opts = {
        google: Geokit::Geocoders::GoogleGeocoder,
        mapbox: Geokit::Geocoders::MapboxGeocoder,
      }
      (@geocoder = geo_opts[self.geocoder_name.to_sym]) or raise "No geocoder available for #{self.geocoder_name}"
    end
  end

  # Maintain timestamp fields automatically
  plugin :timestamps

  #
  # Dataset methods
  #

  dataset_module do
    ### Limit results to those with geocoder data that indicates it's in the US.
    def geocoded_in_the_us
      return self.where(Sequel.pg_jsonb(:geocoder_data).extract_text("country_code") => "US")
    end

    ### Limit results to those with geocoder data that's at one of the given
    ### +precisions+.
    def with_geocoder_precision(*precisions)
      return self.where(Sequel.pg_jsonb(:geocoder_data).extract_text("precision") => precisions)
    end

    ### Limit results to those which have failed geocoding (success is false).
    def failed_geocoding
      return self.where(Sequel.pg_jsonb(:geocoder_data).extract_text("success") => "false")
    end
  end

  ### Create a new unsaved Address by geocoding the specified +address+ string.
  def self.parse_address_string(address, bias="us")
    geoloc = self.geocoder.geocode(address, bias:)

    addr = self.lookup(
      address1: geoloc.street_address,
      city: geoloc.city,
      state_or_province: geoloc.state_code,
      postal_code: geoloc.zip,
      country: geoloc.country_code,
    )
    addr.geocoder_data = geoloc
    addr.save_changes
    return addr
  end

  ### Geocode addr and return a Geokit::GeoLoc object
  def self.geocode(addr)
    ga = addr.geocodable_address
    self.logger.debug "Geocoding %s" % [ga]
    return self.geocoder.geocode(ga, bias: addr.country)
  end

  ### Look for an existing address using +address1+, +address2+,
  ### and +postal_code+. If one does not exist, create a new +Address+.
  ### Apply changes in other fields to the resulting +Address+,
  ### but do not save the changes.
  ###
  ### The idea behind this method is that these 3 "lookup" fields
  ### are the "primary identity" of an address.
  ### All addresses with those three fields refer to the same place.
  ### So we can vary the other fields- for example we do not want
  ### two addresses with the same "primary identity" but different states
  ### (since postal code is unique to state/country).
  ###
  ### This creates some potential issues, where customers can change each other's
  ### addresses (for example, by using the address of an existing property,
  ### but providing a nonsense +city+ field). The original customer would see
  ### a property with an address with the nonsense +city+.
  ###
  ### In practice, this rarely happens, but we may need to do something
  ### about it in the future.
  def self.lookup(fields)
    address_criteria = {
      address1: fields[:address1],
      address2: fields[:address2] || "",
      postal_code: fields[:postal_code],
    }

    addr = self.find_or_create_or_find(address_criteria) do |a|
      # Need to apply defaults if the object is being created (or it cannot be saved),
      # even though we'll reassign them below.
      a.city = fields[:city]
      a.state_or_province = fields[:state_or_province]
      # If lat/lng are given for a new address, we can use them.
      # We expect these to be thrown away during geocode that happens on address create,
      # but if a client supplies them they probably want them to be available immediately.
      a[:lat] = fields[:lat] if fields.key?(:lat)
      a[:lng] = fields[:lng] if fields.key?(:lng)
    end

    # Set address1 and 2 in case passed case is different from stored,
    # those fields are citext.
    keys_to_check = [:address1, :address2, :city, :state_or_province, :country]
    to_set = keys_to_check.each_with_object({}) do |key, memo|
      memo[key] = fields[key] if fields.key?(key)
    end
    addr.set(to_set)

    return addr
  end

  def self.empty
    return self.new(
      address1: "",
      address2: "",
      city: "",
      state_or_province: "",
      postal_code: "",
    )
  end

  ### Set some defaults for new objects.
  def initialize(*)
    super

    self[:country] ||= DEFAULT_COUNTRY
    self[:geocoder_data] ||= Sequel.pg_json({})
  end

  def fields
    return self.geocodable_fields.merge!(address2: self.address2)
  end

  def geocodable_fields
    return {
      address1: self.address1,
      city: self.city,
      state_or_province: self.state_or_province,
      postal_code: self.postal_code,
    }
  end

  ##
  # Alias for #postal_code
  def_column_alias :zip, :postal_code

  ##
  # Alias for #state_or_province
  def_column_alias :state, :state_or_province

  ### Override the model method to wrap the value as a JSON hash.
  def geocoder_data=(geoloc)
    raise ArgumentError, "Must be a Geokit::GeoLoc" unless geoloc.is_a?(Geokit::GeoLoc)
    self[:geocoder_data] = Sequel.pg_json(geoloc.to_hash.stringify_keys)
    self[:lat] = geoloc.lat
    self[:lng] = geoloc.lng
    self[:suggested_bounds_nesw] =
      if (b = geoloc.suggested_bounds)
        [b.ne.lat, b.ne.lng, b.sw.lat, b.sw.lng]
      else
        []
      end
  end

  def lat=(*)
    raise "Must be set through geocoder_data="
  end

  def lng=(*)
    raise "Must be set through geocoder_data="
  end

  def suggested_bounds_nesw=(*)
    raise "Must be set through geocoder_data="
  end

  ### Return the address as a single line in a String.
  def one_line_address(include_country: true)
    one_line_address = [
      self.address1,
      self.address2,
      self.city,
      self.state,
      self.postal_code,
    ]
    one_line_address.push(self.country.upcase) if include_country

    return one_line_address.select(&:present?).join(", ")
  end
  alias to_s one_line_address

  ### Return the address suitable for geocoding.
  def geocodable_address
    return [
      self.address1,
      self.city, self.state, self.postal_code,
      self.country.upcase,
    ].compact.join(", ")
  end

  ### Return an Array of non-nil street address lines.
  def address_lines
    return [self.address1, self.address2].select(&:present?)
  end

  ### Return the address's geographic location if it has one as a human-readable
  ### latitude and longitude. Returns +nil+ if the Address doesn't have a location.
  def location_string
    return unless self.lat
    return "[%0.2f°%s, %0.2f°%s]" % [
      self.lat.abs,
      self.lat.positive? ? "N" : "S",
      self.lng.abs,
      self.lng.positive? ? "E" : "W",
    ]
  end

  def street_view_url(width: 600, height: 400)
    return "https://maps.googleapis.com/maps/api/streetview?" + [
      "location=#{CGI.escape(self.geocodable_address)}",
      "size=#{width}x#{height}",
      "key=#{self.class.google_api_key}",
    ].join("&")
  end

  ### Return a representation of the object as a String, suitable for debugging.
  def inspect
    return %(#<%p:%#x [%s] "%s" %s>) % [
      self.class,
      self.object_id * 2,
      self.pk,
      self.one_line_address,
      self.location_string,
    ]
  end

  # Geocodes the address, and sets fields on the receiver
  # based on the geocoded result.
  def geocode
    self.check_can_geocode!
    needs_geocoding = self.lat.nil? || self.geocoded_address != self.geocodable_address
    self.geocode! if needs_geocoding
    return self
  end

  # Geocode even if the data has not changed.
  # Useful especially when info about an address has changed,
  # as happens commonly in new developments.
  def geocode!
    self.check_can_geocode!
    self.geocoder_data = self.class.geocode(self)
    self.geocoded_address = self.geocodable_address
    self.save_changes
    return self
  end

  protected def check_can_geocode!
    raise "address1 cannot be blank (use class method to bypass this check)" if self.address1.blank?
  end

  #
  # Validations
  #
end

# Table: addresses
# -----------------------------------------------------------------------------------------------------------
# Columns:
#  id                    | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at            | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at            | timestamp with time zone |
#  address1              | citext                   | NOT NULL
#  address2              | citext                   | NOT NULL DEFAULT ''::citext
#  city                  | citext                   | NOT NULL
#  state_or_province     | citext                   | NOT NULL
#  postal_code           | citext                   | NOT NULL
#  country               | citext                   | NOT NULL DEFAULT 'US'::citext
#  lat                   | double precision         |
#  lng                   | double precision         |
#  suggested_bounds_nesw | double precision[]       |
#  geocoder_data         | jsonb                    | NOT NULL DEFAULT '{}'::jsonb
#  geocoded_address      | text                     | NOT NULL DEFAULT ''::text
# Indexes:
#  addresses_pkey                              | PRIMARY KEY btree (id)
#  addresses_address1_address2_postal_code_key | UNIQUE btree (address1, address2, postal_code)
# Referenced By:
#  legal_entities | legal_entities_address_id_fkey | (address_id) REFERENCES addresses(id) ON DELETE SET NULL
# -----------------------------------------------------------------------------------------------------------
