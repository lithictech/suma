# frozen_string_literal: true

require "suma/mobility/trip_importer"

# Sync trips from the Lime CSV report they provide partners.
class Suma::Lime::SyncTripsFromReport
  include Appydays::Loggable

  DEFAULT_VEHICLE_TYPE = Suma::Mobility::ESCOOTER
  TRIP_TOKEN = "TRIP_TOKEN"
  START_TIME = "START_TIME"
  END_TIME = "END_TIME"
  REGION_NAME = "REGION_NAME"
  USER_TOKEN = "USER_TOKEN"
  TRIP_DURATION_MINUTES = "TRIP_DURATION_MINUTES"
  TRIP_DISTANCE_MILES = "TRIP_DISTANCE_MILES"
  ACTUAL_COST = "ACTUAL_COST"
  INTERNAL_COST = "INTERNAL_COST"
  NORMAL_COST = "NORMAL_COST"
  USER_EMAIL = "USER_EMAIL"
  PRICE_PER_MINUTE = "Price per minute"

  def initialize(report_io)
    @csv = CSV.parse(report_io, headers: true)
  end

  def run
    @csv.each do |row|
      if Suma::AnonProxy::VendorAccountRegistration.where(external_program_id: row.fetch(USER_EMAIL)).empty?
        self.logger.warn("lime_report_missing_member",
                         member_contact_email: row.fetch(USER_EMAIL),
                         trip_token: row.fetch(TRIP_TOKEN),)
        next
      end
      ride_id = row.fetch(TRIP_TOKEN)
      return nil unless Suma::Mobility::Trip.where(external_trip_id: ride_id).empty?
      self.create_trip_from_row(row)
    end
  end

  def create_trip_from_row(row)
    registration = Suma::AnonProxy::VendorAccountRegistration.find!(external_program_id: row.fetch(USER_EMAIL))
    vendor_config = registration.account.configuration
    program = Suma::Enumerable.one!(vendor_config.programs)
    pricing = Suma::Enumerable.one!(program.pricings)
    receipt = self.parse_row_to_receipt(row, rate: pricing.vendor_service_rate)
    receipt.trip.set(
      member: registration.account.member,
      vendor_service: pricing.vendor_service,
      vendor_service_rate: pricing.vendor_service_rate,
    )
    Suma::Mobility::TripImporter.import(receipt:, logger: self.logger)
  end

  def parse_row_to_receipt(row, rate:)
    r = Suma::Mobility::TripImporter::Receipt.new
    r.trip.set(
      vehicle_id: row.fetch(TRIP_TOKEN),
      vehicle_type: DEFAULT_VEHICLE_TYPE,
      began_at: parsetime(row.fetch(START_TIME)),
      ended_at: parsetime(row.fetch(END_TIME)),
      external_trip_id: row.fetch(TRIP_TOKEN),
    )
    r.total = Monetize.parse(row.fetch(ACTUAL_COST))
    minutes = r.trip.duration_minutes
    # Unfortunately the cost columns in this report are not correct.
    # INTERNAL_COST should be the Lime Access cost,
    # but it cannot be derived from PRICE_PER_MINUTE and TRIP_DURATION_MINUTES.
    # PRICE_PER_MINUTE is wrong, no idea why it's not consistent.
    # TRIP_DURATION_MINUTES is wrong. 'end - begin in minutes inclusive' gives a more accurate trip length,
    # as verified by comparing it to the trip price.
    # NORMAL_COST may give us the correct full retail cost (if we use proper minute calculation),
    # but we can't get any line item information at that point since we don't know per-minute pricing.
    # So, in the end: use the actual cost they give us,
    # and then use the vendor service to figure out discount.
    Suma.assert do
      r.total == rate.calculate_total(minutes)
    end
    r.discount = rate.discount(minutes)
    r.line_items << r.line_item(amount: rate.surcharge, memo: "Start Fee")
    r.line_items << r.line_item(
      amount: rate.calculate_unit_cost(minutes),
      memo: "Riding - #{rate.unit_amount.format}/min (#{minutes} min)",
    )
    return r
  end

  def parsetime(t) = Time.strptime("#{t} -0700", "%m/%d/%Y %I:%M %p %Z")
end
