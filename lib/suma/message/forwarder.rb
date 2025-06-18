# frozen_string_literal: true

class Suma::Message::Forwarder
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:message_forwarder) do
    setting :phone_numbers, [], convert: ->(s) { s.split.map(&:strip) }
    setting :front_inbox_id, ""
  end

  class << self
    def configured? = self.front_inbox_id.present?
  end

  def initialize(now:)
    @now = now
  end

  def run
    raise Suma::InvalidPrecondition, "NUMBER_FORWARDER_PHONE_NUMBERS must be set" unless
      self.class.configured?
    rows = self.fetch_rows
    inbox_id = Suma::Frontapp.to_inbox_id(self.class.front_inbox_id)
    results = []
    rows.each do |row|
      Suma::Idempotency.once_ever.under_key("sw-forwarder-#{row.fetch(:signalwire_id)}") do
        results << Suma::Frontapp.client.import_message(
          inbox_id,
          {
            sender: {
              handle: Suma::Frontapp.contact_phone_handle(row.fetch(:from)),
            },
            to: [Suma::Frontapp.contact_phone_handle(row.fetch(:from))],
            body: row.fetch(:body),
            external_id: row.fetch(:signalwire_id),
            created_at: row.fetch(:date_created).to_i,
            type: "sms",
            metadata: {
              is_inbound: true,
              is_archived: false,
            },
          },
        )
      end
    end
    return results
  end

  def fetch_rows
    cutoff = @now - 1.week
    ds = Suma::Webhookdb.signalwire_messages_dataset
    ds = ds.where { date_created > cutoff }
    ds = ds.where(
      direction: "inbound",
      to: self.class.phone_numbers.map { |n| Suma::PhoneNumber.format_e164(n) },
    )
    ds = ds.order(:date_created)
    ds = ds.select(:signalwire_id, :date_created, :from, Sequel.pg_json(:data).get_text("body").as(:body))
    return ds.all
  end
end
