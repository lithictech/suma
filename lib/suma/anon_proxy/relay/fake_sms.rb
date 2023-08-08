# frozen_string_literal: true

class Suma::AnonProxy::Relay::FakeSms < Suma::AnonProxy::Relay
  def key = "fake-sms-relay"
  def transport = :sms
  def webhookdb_table = nil
  def provision(member) = "1#{member.id}".ljust(11, "5")
  def format_address(s) = Suma::PhoneNumber::US.format(s)

  def parse_message(row)
    return Suma::AnonProxy::ParsedMessage.new(**row)
  end
end
