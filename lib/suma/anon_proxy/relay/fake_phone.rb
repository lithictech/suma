# frozen_string_literal: true

class Suma::AnonProxy::Relay::FakePhone < Suma::AnonProxy::Relay
  def key = "fake-phone-relay"
  def transport = :phone
  def webhookdb_table = nil
  def provision(member) = "1555#{member.id}".ljust(11, "1")

  def parse_message(row)
    return Suma::AnonProxy::ParsedMessage.new(**row)
  end
end
