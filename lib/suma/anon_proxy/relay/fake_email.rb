# frozen_string_literal: true

require_relative "fake_relay"

class Suma::AnonProxy::Relay::FakeEmail < Suma::AnonProxy::Relay::FakeRelay
  def key = "fake-email-relay"
  def transport = :email

  def provision(member)
    ProvisionedAddress.new(
      "u#{member.id}@example.com", external_id: self.class.provisioned_external_id,
    )
  end
end
