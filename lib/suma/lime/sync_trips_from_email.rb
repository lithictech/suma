# frozen_string_literal: true

require "suma/lime"
require "suma/mobility/trip_importer"

# For all Lime trips we have receipt emails from,
# create mobility trips for them.
# Lime receipt emails are pretty bare, but we do our best!
class Suma::Lime::SyncTripsFromEmail
  include Appydays::Loggable

  DEFAULT_VEHICLE_TYPE = Suma::Mobility::ESCOOTER
  CUTOFF = 2.weeks

  def row_iterator = Suma::Webhookdb::RowIterator.new("lime/synctrips/pk")

  def run
    ds = self.dataset
    self.row_iterator.each(ds) do |row|
      if Suma::AnonProxy::VendorAccountRegistration.where(external_program_id: row.fetch(:to_email)).empty?
        self.logger.warn("lime_receipt_missing_member",
                         member_contact_email: row.fetch(:to_email),
                         webhookdb_row_pk: row.fetch(:pk),)
        next
      end
      ride_id = row.fetch(:message_id)
      return nil unless Suma::Mobility::Trip.where(external_trip_id: ride_id).empty?
      self.create_trip_from_row(row)
    end
  end

  def dataset
    ds = Suma::Webhookdb.postmark_inbound_messages_dataset.
      where(from_email: ["no-reply@li.me"]).
      where(subject: "Receipt for your Lime ride").
      where { timestamp > CUTOFF.ago }
    return ds
  end

  def create_trip_from_row(row)
    registration = Suma::AnonProxy::VendorAccountRegistration.find!(external_program_id: row.fetch(:to_email))
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

  def parse_row_to_receipt(row)
    r = Suma::Mobility::TripImporter::Receipt.new
    r.trip.external_trip_id = row.fetch(:message_id)
    r.trip.vehicle_id = r.trip.external_trip_id
    r.trip.vehicle_type = DEFAULT_VEHICLE_TYPE
    r.trip.ended_at = row.fetch(:timestamp) - 1.minute

    lines = row.fetch(:data).fetch("TextBody").lines.reject(&:blank?).map(&:strip)
    i = 0
    riding_line_item = pause_line_item = nil
    while i < lines.length
      line = lines[i]
      if line == "Start Fee"
        r.line_items << r.line_item(memo: line, amount: Monetize.parse(lines[i + 1]))
        i += 1
      elsif line == "Discount"
        r.discount = Monetize.parse(lines[i + 1]) * -1
        r.line_items << r.line_item(memo: line, amount: -r.discount)
        i += 1
      elsif line.start_with?("Riding -", "Pause -")
        match = line.match(%r{(\$\d+\.\d\d)/min \((\d+) min\)})
        per_minute = Monetize.parse(match[1])
        minutes = match[2].to_i
        line_item = r.line_item(memo: line, amount: Monetize.parse(lines[i + 1]), minutes:, per_minute:)
        if line.start_with?("Riding")
          riding_line_item = line_item
        else
          pause_line_item = line_item
        end
        r.line_items << line_item
        r.trip.began_at = r.trip.ended_at - (minutes * 60)
        i += 1
      elsif line == "Total"
        total = lines[i + 1] == "FREE" ? Money.new(0) : Monetize.parse(lines[i + 1])
        r.total = total
      end
      i += 1
    end
    if pause_line_item && riding_line_item
      # Lime receipt emails have separate minute totals for pause and riding,
      # but the riding charge also contains the pause charge. Not sure why this is!
      # But handle it by reducing the riding charge. Raise an error if it looks wrong, though;
      # this is an email receipt so we should expect it to change without notice.
      expected_riding_total = pause_line_item.amount + (riding_line_item.per_minute * riding_line_item.minutes)
      if expected_riding_total != riding_line_item.amount
        msg = "unexpected pause and riding line items: #{pause_line_item}, #{riding_line_item}"
        raise Suma::InvariantViolation, msg
      end
      riding_line_item.amount -= pause_line_item.amount
    end
    return r
  end
end
