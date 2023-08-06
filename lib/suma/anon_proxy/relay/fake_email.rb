# frozen_string_literal: true

class Suma::AnonProxy::Relay::FakeEmail < Suma::AnonProxy::Relay
  def key = "fake-email-relay"
  def transport = :email
  def webhookdb_table = nil
  def provision(member) = "u#{member.id}@example.com"

  def parse_message(row)
    return Suma::AnonProxy::ParsedMessage.new(**row)
  end
end
