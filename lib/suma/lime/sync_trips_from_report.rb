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
  PRICE_PER_MINUTE = "Price per minute"

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
      where(
        from_email: Suma::Lime.trip_report_from_email,
        to_email: Suma::Lime.trip_report_to_email,
      ).where { timestamp > CUTOFF.ago }
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
        self.logger.warn("lime_report_missing_member",
                         member_contact_email: row.fetch(USER_EMAIL),
                         trip_token: row.fetch(TRIP_TOKEN),)
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
    receipt = self.parse_row_to_receipt(row)
    receipt.trip.set(
      member: registration.account.member,
      vendor_service: pricing.vendor_service,
      vendor_service_rate: pricing.vendor_service_rate,
    )
    Suma::Mobility::TripImporter.import(receipt:, logger: self.logger)
  end

  # Convert a CSV report row into a parsed receipt.
  # Unfortunately this report is a bit of a mess, but we need to use it,
  # so here is a long explanation.
  #
  # There are 3 prices in this report:
  # - The full, undiscounted retail price, which we'll call 'undiscounted retail price' (URP)
  # - The Lime Access price, which we'll call the 'discounted retail price' (DRP)
  # - How much Lime charged suma (which is what suma will charge the member), which we'll call the 'suma price' (SP)
  #
  # We need to get enough information to show the user a line-itemed receipt of what they were charged,
  # along with the full undiscounted price.
  #
  # Lime tells us some information in its report, but much of it is wrong.
  # So we need to both use and derive necessary information.
  #
  # - PRICE_PER_MINUTE is wrong and unusable. It seems to vary between 7 and 9 cents.
  # - TRIP_DURATION_MINUTES is wrong, and we don't need to use it.
  #   'end - begin in minutes inclusive' gives a more accurate trip length,
  #   as verified by comparing it to the trip price.
  # - INTERNAL_COST is the Lime Access cost (DRP), and we can ignore it.
  # - NORMAL_COST gives us the correct full retail cost, verified when we use proper minute calculation.
  #   Since we don't need line item information, we can use this as the URP.
  # - ACTUAL_COST is what Lime charged the user's account (suma). This is the SP.
  #
  # However, to make a receipt useful, we need to provide line items:
  # - Unlock cost
  # - Per-minute cost and ride cost.
  #
  # Since we have to ignore PRICE_PER_MINUTE (it's inconsistent,
  # and it's not clear if it would map correctly to INTERNAL_COST anyway),
  # we *must* use our pricing to 'undiscounted pricing' to get the per-minute URP cost.
  #
  # We can then subtract that ride cost from the NORMAL_COST to get the unlock fee.To get URP, we can just use NORMAL_COST. We prefer this over calculating it ourselves from a Vendor::Service::Rate.
  #
  # We don't actually care about DRP. This is only relevant for storytelling about platform value.
  # We only care about the SP and URP when it comes to platform costs and savings.
  #
  # When we calculate SP,
  def parse_row_to_receipt(row)
    r = Suma::Mobility::TripImporter::Receipt.new
    r.trip.set(
      vehicle_id: row.fetch(TRIP_TOKEN),
      vehicle_type: DEFAULT_VEHICLE_TYPE,
      began_at: parsetime(row.fetch(START_TIME)),
      ended_at: parsetime(row.fetch(END_TIME)),
      external_trip_id: row.fetch(TRIP_TOKEN),
    )
    # Unfortunately the cost columns in this report are not correct.
    # However, since what Lime lists as its cost, and what it charges suma, are based on out-of-band mechanics,
    # NOT our suma service rates, we need to use what Lime tells us, always.
    # Here are some notes on the problems with the columns as of early October 2025.
    #
    #
    #
    # This is the only Lime column we can ignore.
    #
    # INTERNAL_COST should be the Lime Access cost,
    # but it cannot be derived from PRICE_PER_MINUTE and TRIP_DURATION_MINUTES,
    # since both are independently wrong.
    # However, we need to use this column to derive the 'unlock cost'
    #
    #
    #
    #
    #
    undiscounted_cost = Monetize.parse(row.fetch(NORMAL_COST))
    r.total = Monetize.parse(row.fetch(ACTUAL_COST))
    r.discount = undiscounted_cost - r.total
    per_minute_rate = Monetize.parse(row.fetch(PRICE_PER_MINUTE))
    minutes = r.trip.duration_minutes
    riding_cost = per_minute_rate * r.trip.duration_minutes
    unlock_cost = undiscounted_cost - riding_cost
    r.line_items << r.line_item(amount: rate.surcharge, memo: "Start Fee")
    r.line_items << r.line_item(
      amount: riding_cost,
      memo: "Riding - #{per_minute_rate.format}/min (#{minutes} min)",
    )
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
