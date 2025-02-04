# frozen_string_literal: true

class Suma::Message::SignalwireWebhookdbOptoutProcessor
  include Appydays::Loggable

  OPTINOUT = [:optout, :optin].freeze

  def initialize(now:)
    @now = now
  end

  def run
    rows = self.fetch_rows
    rows.each do |row|
      from = row.fetch(:from)
      raise Suma::InvariantViolation, "unexpected signalwire phone: #{from}" unless from.first == "+"
      member = Suma::Member[phone: from[1..]]
      next if member.nil?
      # Transactions are ok for idempotency because there are no 3rd party actions,
      # so as long as everything is committed we're ok.
      Suma::Idempotency.once_ever.transaction_ok.under_key("sw-whdb-optout-#{row.fetch(:signalwire_id)}") do
        msgtype = self.msgtype(row.fetch(:body))
        member.message_preferences!.update(marketing_sms_optout: msgtype == :optout) if OPTINOUT.include?(msgtype)
        msg = Suma::Messages::SingleValue.new(
          "sms_compliance",
          msgtype.to_s,
          "",
        )
        member.message_preferences!.dispatch(msg)
      end
    end
  end

  def fetch_rows
    cutoff = @now - 1.week
    ds = Suma::Webhookdb.signalwire_messages_dataset
    ds = ds.where { date_created > cutoff }
    ds = ds.where(
      direction: "inbound",
      to: Suma::Signalwire.marketing_number,
    )
    keywords = Suma::Signalwire.message_marketing_sms_unsubscribe_keywords +
      Suma::Signalwire.message_marketing_sms_resubscribe_keywords +
      Suma::Signalwire.message_marketing_sms_help_keywords
    ds = ds.where(
      Sequel.function(:upper,
                      Sequel.function(:trim,
                                      Sequel.pg_jsonb(:data).get_text("body"),),) => keywords,
    )
    ds = ds.order(:date_created)
    ds = ds.select(:signalwire_id, :from, Sequel.pg_json(:data).get_text("body").as(:body))
    return ds.all
  end

  def msgtype(body)
    b = body.upcase.strip
    return :optout if Suma::Signalwire.message_marketing_sms_unsubscribe_keywords.include?(b)
    return :optin if Suma::Signalwire.message_marketing_sms_resubscribe_keywords.include?(b)
    return :help if Suma::Signalwire.message_marketing_sms_help_keywords.include?(b)
    raise Suma::InvariantViolation, "Unhandled body, should not have been selected: #{body}"
  end
end
