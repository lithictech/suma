# frozen_string_literal: true

class Suma::AnonProxy::Relay::Fake < Suma::AnonProxy::Relay
  def key = "fake-relay"
  def transport = :email
  def provision(member) = "u#{member.id}@example.com"

  def parse_message(row)
    return Suma::AnonProxy::ParsedMessage.new(**row)
  end
end
