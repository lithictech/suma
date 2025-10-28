# frozen_string_literal: true

require "suma/admin_linked"
require "suma/charge/charger"
require "suma/charge/has"
require "suma/mobility"
require "suma/postgres/model"

class Suma::Mobility::Trip < Suma::Postgres::Model(:mobility_trips)
  include Suma::AdminLinked
  include Suma::Charge::Has
  include Suma::Image::SingleAssociatedMixin
  include Suma::Postgres::HybridSearch

  class OngoingTrip < StandardError; end

  plugin :hybrid_search
  plugin :money_fields, :our_cost
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

  def self.start_trip_from_vehicle(member:, vehicle:, rate:, now: Time.now)
    return self.start_trip(
      member:,
      vehicle_id: vehicle.vehicle_id,
      vehicle_type: vehicle.vehicle_type,
      vendor_service: vehicle.vendor_service,
      rate:,
      lat: vehicle.lat,
      lng: vehicle.lng,
      now:,
    )
  end

  # Start a trip through a mobility adapter.
  # This is the "synchronous" trip start endpoint, where suma tells the vendor adapter
  # about a trip actively starting.
  # If this is a historical trip, use +import_trip+ instead.
  def self.start_trip(
    member:,
    vehicle_id:,
    vehicle_type:,
    vendor_service:,
    rate:,
    lat:,
    lng:,
    now:
  )
    vendor_service.guard_usage!(member, rate:, now:)
    self.db.transaction(savepoint: true) do
      trip = self.new(
        member:,
        vehicle_id:,
        vehicle_type:,
        vendor_service:,
        vendor_service_rate: rate,
        begin_lat: lat,
        begin_lng: lng,
        began_at: now,
      )
      vendor_service.mobility_adapter.trip_provider.begin_trip(trip)
      trip.save_changes
    rescue Sequel::UniqueConstraintViolation => e
      raise OngoingTrip, "member #{member.id} is already in a trip" if
        e.to_s.include?("one_active_ride_per_member")
      raise
    end
  end

  # End a trip through the mobility adapter. Charge the member any outstanding cost.
  def end_trip(lat:, lng:, now:)
    self.set(end_lat: lat, end_lng: lng, ended_at: now)
    result = self.vendor_service.mobility_adapter.trip_provider.end_trip(self)
    self.charge_trip(result)
  end

  # Save and charge the trip.
  # The cost is paid for by whatever is on the member ledgers, payment triggers,
  # plus a funding transaction is created for any outstanding amount.
  #
  # The funding transaction processes asynchronously,
  # so it may fail even if this method succeeds (though one will always be created if needed).
  #
  # If the funding transaction is required but cannot be created (no payment method),
  # create a support ticket; the member ledger will be negative.
  # @param end_trip_result [Suma::Mobility::EndTripResult]
  def charge_trip(end_trip_result)
    # This would be bad, but we should know when it happens and pick up the pieces
    # instead of trying to figure out a solution to an impossible problem.
    raise Suma::InvalidPrecondition, "negative trip cost for #{self.inspect}" if
      end_trip_result.line_items.sum(&:amount).negative?
    self.db.transaction do
      self._charge_trip(end_trip_result)
    end
  end

  def _charge_trip(result)
    self.save_changes
    charged_off_platform = result.charged_off_platform || Money.zero
    total_cost = result.line_items.sum(&:amount) - charged_off_platform
    charger = Charger.new(
      trip: self,
      customer_cost: total_cost,
      member: self.member,
      apply_at: result.charge_at,
      undiscounted_subtotal: result.undiscounted_cost,
      charge_kwargs: {mobility_trip: self, off_platform_amount: charged_off_platform},
    )
    charge = charger.charge
    result.line_items.each do |li|
      charge.add_line_item(amount: li.amount, memo: Suma::TranslatedText.create(all: li.memo))
    end
  end

  class Charger < Suma::Charge::Charger
    def initialize(trip:, customer_cost:, **)
      @trip = trip
      @customer_cost = customer_cost
      super(**)
    end

    def predicted_charge_contributions
      return Suma::Payment::ChargeContribution.find_ideal_cash_contribution(
        Suma::Payment::CalculationContext.new(self.apply_at),
        self.member.payment_account,
        @trip.vendor_service,
        @customer_cost,
      )
    end

    def verify_predicted_contribution(_contrib)
      nil
    end

    def actual_charge_contributions
      return Suma::Payment::ChargeContribution.find_actual_contributions(
        Suma::Payment::CalculationContext.new(self.apply_at),
        self.member.payment_account,
        @trip.vendor_service,
        @customer_cost,
      )
    end

    def contribution_memo
      return Suma::TranslatedText.create(all: "#{@trip.vendor_service.external_name} - #{@trip.opaque_id}")
    end

    def start_funding_transaction(amount:)
      if (instrument = self.member.default_payment_instrument)
        # If we have a remainder, we need to create a funding transaction to cover it.
        # Since the ride already happened, we want to collect this later, not now-
        # if the funding fails, we handle it like any other fialed funding.
        return Suma::Payment::FundingTransaction.start_new(
          self.member.payment_account,
          amount:,
          instrument:,
          collect: false,
        )
      end
      Suma::Support::Ticket.create(
        sender_name: "Suma Mobility",
        subject: "Member has no payment instrument",
        body: "Member[#{self.member.id}] #{self.member.name} has no payment instrument and " \
              "could not be charged #{amount.format} for Trip[#{@trip.id}] " \
              "from #{@trip.vendor_service.internal_name}. The unpaid balance is on their ledger.",
      )
      return nil
    end
  end

  def ended? = !self.ended_at.nil?
  def ongoing? = self.ended_at.nil?

  def duration
    return nil if self.ongoing?
    return self.ended_at - self.began_at
  end

  def duration_minutes
    d = self.duration
    # Ongoing: return nil
    return nil if d.nil?
    # No duration: return 0 duration
    return 0 if d.zero?
    div, remainder = d.to_i.divmod(60)
    # Less than 60 seconds: return 1 minute
    return 1 if div.zero?
    # On a minute boundary (60, 120, etc.): return 1, 2, etc
    return div if remainder.zero?
    # All other seconds (1, 61, 119, etc.): round minute up
    return div + 1
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

  def rel_app_link = "/trip/#{self.id}"

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
