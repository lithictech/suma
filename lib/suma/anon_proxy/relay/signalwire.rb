# frozen_string_literal: true

class Suma::AnonProxy::Relay::Signalwire < Suma::AnonProxy::Relay
  def key = "signalwire"
  def transport = :phone
  def webhookdb_table = Suma::Webhookdb.signalwire_messages_table

  def provision(member); end

  def parse_message(row)
    return Suma::AnonProxy::ParsedMessage.new(
      message_id: row.fetch(:signalwire_id),
      to: Suma::PhoneNumber::US.normalize(row.fetch(:to)),
      from: Suma::PhoneNumber::US.normalize(row.fetch(:from)),
      content: row.fetch(:data).fetch("body"),
      timestamp: row.fetch(:date_created),
    )
  end
end
