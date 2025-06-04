# frozen_string_literal: true

require_relative "fake_relay"

class Suma::AnonProxy::Relay::FakePhone < Suma::AnonProxy::Relay::FakeRelay
  def key = "fake-phone-relay"
  def transport = :phone

  def provision(member)
    ProvisionedAddress.new(
      "1555#{member.id}".ljust(11, "1"), external_id: self.class.provisioned_external_id,
    )
  end
end
