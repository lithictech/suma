# frozen_string_literal: true

require "suma/mobility"
require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Mobility::Trip < Suma::Postgres::Model(:mobility_trips)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked
  include Suma::Image::SingleAssociatedMixin

  class OngoingTrip < StandardError; end

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :vendor_service, key: :vendor_service_id, class: "Suma::Vendor::Service"
  many_to_one :vendor_service_rate, key: :vendor_service_rate_id, class: "Suma::Vendor::ServiceRate"
  many_to_one :member, key: :member_id, class: "Suma::Member"
  one_to_one :charge, key: :mobility_trip_id, class: "Suma::Charge"

  dataset_module do
    def ongoing = self.where(ended_at: nil)
    def ended = self.exclude(ended_at: nil)
  end

  def initialize(*)
    super
    self.opaque_id ||= Suma::Secureid.new_opaque_id("trp")
  end

  def self.start_trip_from_vehicle(member:, vehicle:, rate:, at: Time.now)
    return self.start_trip(
      member:,
      vehicle_id: vehicle.vehicle_id,
      vehicle_type: vehicle.vehicle_type,
      vendor_service: vehicle.vendor_service,
      rate:,
      lat: vehicle.lat,
      lng: vehicle.lng,
      at:,
    )
  end

  def self.start_trip(member:, vehicle_id:, vehicle_type:, vendor_service:, rate:, lat:, lng:, at: Time.now, **kw)
    vendor_service.guard_usage!(member, rate:, now: at)
    self.db.transaction(savepoint: true) do
      # noinspection RubyArgCount
      trip = self.new(
        member:,
        vehicle_id:,
        vehicle_type:,
        vendor_service:,
        vendor_service_rate: rate,
        begin_lat: lat,
        begin_lng: lng,
        began_at: at,
        **kw,
      )
      vendor_service.mobility_adapter.begin_trip(trip)
      trip.save_changes
    rescue Sequel::UniqueConstraintViolation => e
      raise OngoingTrip, "member #{member.id} is already in a trip" if
        e.to_s.include?("one_active_ride_per_member")
      raise
    end
  end

  def end_trip(lat:, lng:, at: Time.now, adapter_kw: {})
    # Not sure how to handle API multiple calls to a 3rd party service for the same trip,
    # or if we lose track of something (out of sync between us and service).
    # We can work this out more clearly once we have more providers to work with.
    result = self.vendor_service.mobility_adapter.end_trip(self, **adapter_kw)
    # This would be bad, but we should know when it happens and pick up the pieces
    # instead of trying to figure out a solution to an impossible problem.
    raise Suma::InvalidPostcondition, "negative trip cost for #{self.inspect}" if result.cost.negative?
    self.db.transaction do
      self.update(end_lat: lat, end_lng: lng, ended_at: result.end_time)
      self.charge = Suma::Charge.create(
        mobility_trip: self,
        undiscounted_subtotal: result.undiscounted,
        member: self.member,
      )
      contrib_coll = self.member.payment_account!.calculate_charge_contributions(
        Suma::Payment::CalculationContext.new(at),
        self.vendor_service,
        result.cost,
      )
      debitable_contribs = contrib_coll.all.select(&:amount?)
      book_xactions = self.member.payment_account.debit_contributions(
        debitable_contribs,
        memo: Suma::TranslatedText.create(all: "#{self.vendor_service.external_name} - #{self.opaque_id}"),
      )
      book_xactions.each { |x| self.charge.add_line_item(book_transaction: x) }
      if contrib_coll.remainder?
        instrument = self.member.default_payment_instrument or
          raise Suma::InvalidPrecondition, "member #{self.member.id} has no payment instrument"
        # If we have a remainder, we need to create a funding transaction to cover it.
        # Since the ride already happened, we want to collect this later, not now-
        # if the funding fails, we handle it like any other fialed funding.
        funding = Suma::Payment::FundingTransaction.start_new(
          Suma::Payment.as_account(self.member),
          amount: contrib_coll.remainder,
          instrument:,
          collect: false,
        )
        self.charge.add_associated_funding_transaction(funding)
      end
      return self.charge
    end
  end

  def self.import_trip(
    member:,
    vehicle_id:,
    vehicle_type:,
    vendor_service:,
    rate:,
    begin_lat:,
    begin_lng:,
    began_at:,
    end_lat:,
    end_lng:,
    ended_at:,
    adapter_kw: {},
    **kw
  )
    trip = self.new(
      member:,
      vehicle_id:,
      vehicle_type:,
      vendor_service:,
      vendor_service_rate: rate,
      begin_lat: begin_lat,
      begin_lng: begin_lng,
      began_at: began_at,
      # We must set the end fields here so we don't hit an issue with the ongoing trip constraint.
      end_lat:,
      end_lng:,
      ended_at:,
      **kw,
    )
    vendor_service.mobility_adapter.begin_trip(trip)
    trip.save_changes
    trip.end_trip(lat: end_lat, lng: end_lng, at: ended_at, adapter_kw:)
    return trip
  end

  def ended? = !self.ended_at.nil?
  def ongoing? = self.ended_at.nil?

  def duration
    return nil if self.ongoing?
    return self.ended_at - self.began_at
  end

  def duration_minutes
    return -1 if self.ongoing?
    r = self.duration.to_i / 1.minute
    r = 1 if r <= 0
    return r
  end

  def begin_address_parsed = self.parse_address(self.begin_address)
  def end_address_parsed = self.parse_address(self.end_address)

  protected def parse_address(address)
    return nil if address.blank?
    part1, part2 = address.split(",", 2).map(&:strip)
    part2 ||= ""
    part2 = part2.gsub(/, United States$/, "")
    return {part1:, part2:}
  end

  def rel_admin_link = "/mobility-trip/#{self.id}"

  def hybrid_search_fields
    return [
      :external_trip_id,
      :vehicle_id,
      :member,
      ["Vendor", self.vendor_service.vendor.name],
    ]
  end

  def validate
    super
    self.validates_includes Suma::Mobility::VEHICLE_TYPE_STRINGS, :vehicle_type
  end
end

# Table: mobility_trips
# -------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                     | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at             | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at             | timestamp with time zone |
#  vehicle_id             | text                     | NOT NULL
#  vendor_service_id      | integer                  | NOT NULL
#  begin_lat              | numeric                  | NOT NULL
#  begin_lng              | numeric                  | NOT NULL
#  began_at               | timestamp with time zone | NOT NULL
#  end_lat                | numeric                  |
#  end_lng                | numeric                  |
#  ended_at               | timestamp with time zone |
#  vendor_service_rate_id | integer                  | NOT NULL
#  member_id              | integer                  | NOT NULL
#  external_trip_id       | text                     |
#  opaque_id              | text                     | NOT NULL
#  search_content         | text                     |
#  search_embedding       | vector(384)              |
#  search_hash            | text                     |
#  vehicle_type           | text                     | NOT NULL
#  begin_address          | text                     |
#  end_address            | text                     |
# Indexes:
#  mobility_trips_pkey                               | PRIMARY KEY btree (id)
#  mobility_trips_external_trip_id_key               | UNIQUE btree (external_trip_id)
#  mobility_trips_opaque_id_key                      | UNIQUE btree (opaque_id)
#  one_active_ride_per_member                        | UNIQUE btree (member_id) WHERE ended_at IS NULL
#  mobility_trips_member_id_index                    | btree (member_id)
#  mobility_trips_search_content_tsvector_index      | gin (to_tsvector('english'::regconfig, search_content))
#  mobility_trips_vehicle_id_vendor_service_id_index | btree (vehicle_id, vendor_service_id)
# Check constraints:
#  end_fields_set_together | (end_lat IS NULL AND end_lng IS NULL AND ended_at IS NULL OR end_lat IS NOT NULL AND end_lng IS NOT NULL AND ended_at IS NOT NULL)
# Foreign key constraints:
#  mobility_trips_member_id_fkey              | (member_id) REFERENCES members(id)
#  mobility_trips_vendor_service_id_fkey      | (vendor_service_id) REFERENCES vendor_services(id) ON DELETE RESTRICT
#  mobility_trips_vendor_service_rate_id_fkey | (vendor_service_rate_id) REFERENCES vendor_service_rates(id) ON DELETE RESTRICT
# Referenced By:
#  charges | charges_mobility_trip_id_fkey | (mobility_trip_id) REFERENCES mobility_trips(id) ON DELETE SET NULL
#  images  | images_mobility_trip_id_fkey  | (mobility_trip_id) REFERENCES mobility_trips(id)
# -------------------------------------------------------------------------------------------------------------------------------------------------------------
