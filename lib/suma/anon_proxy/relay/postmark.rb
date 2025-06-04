# frozen_string_literal: true

class Suma::AnonProxy::Relay::Postmark < Suma::AnonProxy::Relay
  def key = "postmark"
  def transport = :email
  def webhookdb_table = Suma::Webhookdb.postmark_inbound_messages_table
  def provision(member) = ProvisionedAddress.new(Suma::AnonProxy.postmark_email_template % {member_id: member.id})

  def parse_message(row)
    return Suma::AnonProxy::ParsedMessage.new(
      message_id: row.fetch(:message_id),
      to: row.fetch(:to_email),
      from: row.fetch(:from_email),
      content: row.fetch(:data).fetch("HtmlBody"),
      timestamp: row.fetch(:timestamp),
    )
  end
end
