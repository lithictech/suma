# frozen_string_literal: true

require "amigo/job"
require "suma/async"

class Suma::Async::AnonProxyMemberContactDestroyedResourceCleanup
  extend Amigo::Job

  def perform(opts)
    relay = Suma::AnonProxy::Relay.create!(opts.fetch("relay_key"))
    addr = Suma::AnonProxy::Relay::ProvisionedAddress.new(opts.fetch("address"),
                                                          external_id: opts.fetch("external_id"),)
    relay.deprovision(addr)
  end
end
