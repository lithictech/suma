# frozen_string_literal: true

require "suma/mobility"
require "suma/postgres/model"

class Suma::Mobility::Trip < Suma::Postgres::Model(:mobility_trips)
  class OngoingTrip < StandardError; end

  plugin :timestamps

  many_to_one :vendor_service, key: :vendor_service_id, class: "Suma::Vendor::Service"
  many_to_one :vendor_service_rate, key: :vendor_service_rate_id, class: "Suma::Vendor::ServiceRate"
  many_to_one :customer, key: :customer_id, class: "Suma::Customer"
  one_to_one :charge, key: :mobility_trip_id, class: "Suma::Charge"

  dataset_module do
    def ongoing
      return self.where(ended_at: nil)
    end
  end

  def self.start_trip_from_vehicle(customer:, vehicle:, rate:, at: Time.now)
    return self.start_trip(
      customer:,
      vehicle_id: vehicle.vehicle_id,
      vendor_service: vehicle.vendor_service,
      rate:,
      lat: vehicle.lat,
      lng: vehicle.lng,
      at:,
    )
  end

  def self.start_trip(customer:, vehicle_id:, vendor_service:, rate:, lat:, lng:, at: Time.now)
    customer.read_only_mode!
    self.db.transaction(savepoint: true) do
      return self.create(
        customer:,
        vehicle_id:,
        vendor_service:,
        vendor_service_rate: rate,
        begin_lat: lat,
        begin_lng: lng,
        began_at: at,
      )
    rescue Sequel::UniqueConstraintViolation => e
      raise OngoingTrip, "customer #{customer.id} is already in a trip" if
        e.to_s.include?("one_active_ride_per_customer")
      raise
    end
  end

  def end_trip(lat:, lng:)
    # TODO: Not sure how to handle API multiple calls to a 3rd party service for the same trip,
    # or if we lose track of something (out of sync between us and service).
    # We can work this out more clearly once we have a real provider to work with.
    result = self.vendor_service.mobility_adapter.end_trip(self)
    # This would be bad, but we should know when it happens and pick up the pieces
    # instead of trying to figure out a solution to an impossible problem.
    raise Suma::InvalidPostcondition, "negative trip cost for #{self.inspect}" if result.cost_cents.negative?
    self.db.transaction do
      self.update(end_lat: lat, end_lng: lng, ended_at: result.end_time)
      # The calculated rate can be different than the service actually
      # charges us, so if we aren't using a discount, always use
      # what we end up getting actually charged.
      undiscounted_subtotal = if self.vendor_service_rate.undiscounted_rate.nil?
                                Money.new(result.cost_cents, result.cost_currency)
      else
        self.vendor_service_rate.calculate_undiscounted_total(self.rate_units)
      end
      self.charge = Suma::Charge.create(
        mobility_trip: self,
        undiscounted_subtotal:,
        customer: self.customer,
      )
      result_cost = Money.new(result.cost_cents, result.cost_currency)
      contributions = self.customer.payment_account!.find_chargeable_ledgers(
        self.vendor_service,
        result_cost,
        # At this point, ride has been taken and finished so we need to accept it
        # and deal with a potential negative balance.
        allow_negative_balance: true,
      )
      xactions = self.customer.payment_account.debit_contributions(
        contributions,
        memo: "Suma Mobility - #{self.vendor_service.external_name}",
      )
      xactions.each { |x| self.charge.add_book_transaction(x) }
      return self.charge
    end
  end

  def ended?
    return !self.ended_at.nil?
  end

  def rate_units
    x = self.ended_at - self.began_at
    x /= 60
    x = x.round
    return x
  end
end
