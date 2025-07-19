# frozen_string_literal: true

class Suma::AnonProxy::Relay::Postmark < Suma::AnonProxy::Relay
  def key = "postmark"
  def transport = :email
  def webhookdb_dataset = Suma::Webhookdb.postmark_inbound_messages_dataset

  def provision(member)
    email = "m#{member.id}.#{Time.now.to_i}@#{Suma::AnonProxy.postmark_email_domain}"
    email = "#{Suma::RACK_ENV}.#{email}" if Suma::RACK_ENV != "production"
    ProvisionedAddress.new(email)
  end

  def deprovision(_addr) = nil

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
