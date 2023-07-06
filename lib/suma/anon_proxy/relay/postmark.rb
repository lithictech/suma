# frozen_string_literal: true

class Suma::AnonProxy::Relay::Postmark < Suma::AnonProxy::Relay
  def key = "postmark"
  def transport = :email
  def provision(member) = Suma::AnonProxy.postmark_email_template % {member_id: member.id}

  def parse_message(row)
    return Suma::AnonProxy::ParsedMessage.new(
      message_id: row.fetch(:message_id),
      to: row.fetch(:to_email),
      from: row.fetch(:from_email),
      content: row.fetch(:data).fetch("HtmlBody"),
      timestamp: row.fetch(:timestamp),
    )
  end

  def lookup_member(to)
    id = to[1..].split("@").first
    m = Suma::Member[id: id.to_i]
    return m if m
    raise Suma::InvalidPostcondition, "no valid member #{id} parsed from #{to}"
  end
end
