# frozen_string_literal: true

require "suma/lime"
require "suma/mobility/trip_importer"

# Sync trips from the Lime CSV report they provide partners.
class Suma::Lime::SyncTripsFromReport
  include Appydays::Loggable

  DEFAULT_VEHICLE_TYPE = Suma::Mobility::ESCOOTER
  CUTOFF = 2.weeks

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

  def row_iterator = Suma::Webhookdb::RowIterator.new("lime/synctripsreport/pk")

  def run
    ds = self.dataset
    ds = ds.select(:pk, Sequel.pg_jsonb(:data).get("Attachments").get(0).get_text("Content").as(:content))
    self.row_iterator.each(ds) do |row|
      b64content = row.fetch(:content)
      content = Base64.decode64(b64content)
      self.run_for_report(content)
    end
  end

  def dataset
    ds = Suma::Webhookdb.postmark_inbound_messages_dataset.
      grep(:from_email, Suma::Lime.trip_report_from_email).
      where(to_email: Suma::Lime.trip_report_to_email).
      where { timestamp > CUTOFF.ago }
    return ds
  end

  def run_for_report(txt)
    csv = CSV.parse(txt, headers: true)
    csv.each do |row|
      reg_ds = Suma::AnonProxy::VendorAccountRegistration.where(
        account: Suma::AnonProxy::VendorAccount.where(configuration_id: Suma::Lime.trip_report_vendor_configuration_id),
        external_program_id: row.fetch(USER_EMAIL),
      )
      if reg_ds.empty?
        args = {member_contact_email: row.fetch(USER_EMAIL), trip_token: row.fetch(TRIP_TOKEN)}
        self.logger.warn("lime_report_missing_member", args)
        Sentry.capture_message("Lime trip taken by unknown user") do |scope|
          scope.set_extras(args)
        end
        next
      end
      ride_id = row.fetch(TRIP_TOKEN)
      next unless Suma::Mobility::Trip.where(external_trip_id: ride_id).empty?
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
    Suma::Mobility::TripImporter.import(receipt:, program:, logger: self.logger)
  end

  # Convert a CSV row into a receipt for trip import.
  # Note that we use our own rates for all Lime pricing;
  # using anonymous accounts means we resemble a flow much more like
  # suma retailing Lime trips.
  #
  # The only price column we keep track of is ACTUAL_COST;
  # this is what Lime charges suma.
  def parse_row_to_receipt(row, rate:)
    r = Suma::Mobility::TripImporter::Receipt.new
    r.trip.set(
      vehicle_id: row.fetch(TRIP_TOKEN),
      vehicle_type: DEFAULT_VEHICLE_TYPE,
      began_at: parsetime(row.fetch(START_TIME)),
      ended_at: parsetime(row.fetch(END_TIME)),
      external_trip_id: row.fetch(TRIP_TOKEN),
      our_cost: Monetize.parse(row.fetch(ACTUAL_COST)),
    )
    r.charged_at = r.trip.began_at
    r.paid_off_platform_amount = Money.zero
    r.subsidized_off_platform_amount = Money.zero

    if Monetize.parse(row.fetch(INTERNAL_COST)).zero?
      # If Lime wrote off the charge, it's because the ride was canceled (too short, didn't move, etc.).
      # We do NOT want to charge, or claim we charged, the user anything in this case.
      r.undiscounted_subtotal = Money.zero
      r.misc_line_items << Suma::Mobility::EndTripResult::LineItem.new(
        memo: "Ride cancelled",
        amount: Money.zero,
      )
    else
      r.undiscounted_subtotal = rate.calculate_undiscounted_total(r.trip.duration_minutes)
      r.unlock_fee = rate.surcharge
      r.per_minute_fee = rate.unit_amount
    end
    return r
  end

  def parsetime(t)
    date, time, ampm = t.split
    hr, min = time.split(":")
    # Turn 12 AM into 00 AM
    hr = "00" if hr == "12" && ampm == "AM"
    return Time.strptime("#{date} #{hr}:#{min} -0700", "%m/%d/%Y %H:%M %Z")
  end
end
