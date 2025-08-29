# frozen_string_literal: true

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
    registration.db.transaction(savepoint: true) do
      begin
        trip = Suma::Mobility::Trip.start_trip(
          member: registration.account.member,
          vehicle_id: receipt.ride_id,
          vehicle_type: receipt.vehicle_type,
          vendor_service: pricing.vendor_service,
          rate: pricing.vendor_service_rate,
          lat: 0,
          lng: 0,
          at: receipt.started_at,
          ended_at: receipt.ended_at,
          end_lat: 0,
          end_lng: 0,
          external_trip_id: receipt.ride_id,
        )
      rescue Sequel::UniqueConstraintViolation
        self.logger.debug("ride_already_exists", ride_id:)
        raise Sequel::Rollback
      end

      charge = trip.end_trip(lat: 0, lng: 0, adapter_kw: {receipt:})
      receipt[:line_items].each do |li|
        charge.add_off_platform_line_item(
          amount: li[:amount],
          memo: Suma::TranslatedText.create(all: li[:memo]),
        )
      end
    end
  end

  LINE_ITEM_HEADINGS = ["Start Fee", "Discount"].freeze

  def parse_row_to_receipt(row)
    r = Suma::Mobility::VendorAdapter::LimeDeeplink::RideReceipt.new(
      vehicle_type: DEFAULT_VEHICLE_TYPE,
      ride_id: row.fetch(:message_id),
      ended_at: row.fetch(:timestamp) - 1.minute,
      line_items: [],
    )
    lines = row.fetch(:data).fetch("TextBody").lines.reject(&:blank?).map(&:strip)
    i = 0
    while i < lines.length
      line = lines[i]
      if LINE_ITEM_HEADINGS.include?(line)
        r.line_items << {memo: line, amount: Monetize.parse(lines[i + 1])}
        i += 1
      elsif line.start_with?("Riding -")
        r.line_items << {memo: line, amount: Monetize.parse(lines[i + 1])}
        minutes = line[/\((\d+) min\)/, 1].to_i
        r.started_at = r.ended_at - (minutes * 60)
        i += 1
      elsif line == "Total"
        total = lines[i + 1] == "FREE" ? Money.new(0) : Monetize.parse(lines[i + 1])
        r.total = total
      end
      i += 1
    end
    return r
  end
end
