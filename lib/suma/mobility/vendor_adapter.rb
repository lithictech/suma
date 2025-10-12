# frozen_string_literal: true

require "suma/mobility/trip_provider"

# Mobility vendor adapters map the behavior of a mobility vendor service
# to the underlying provider. Providers use either deep linking into their own apps,
# or provide a 'mobility as a service' platform that suma uses directly.
#
# Deep-linking vendor adapters must have +uses_deep_linking+ true,
# +deeplink_vendor+ set, and +trip_provider_key+ as empty string.
#
# MaaS vendor adapters must have +uses_deep_linking+ false,
# +deeplink_vendor+ nil, and +trip_provider_key+ set.
#
class Suma::Mobility::VendorAdapter < Suma::Postgres::Model(:mobility_vendor_adapters)
  many_to_one :vendor_service, class: "Suma::Vendor::Service"

  # Return the trip manager for this vendor adapter.
  # @return [Suma::Mobility::TripProvider]
  def trip_provider
    Suma.assert { !self.uses_deep_linking }
    Suma::Mobility::TripProvider.registry_create!(self.trip_provider_key)
  end

  # Should be true for Deep Link adapters.
  #
  # @param [true,false]
  def uses_deep_linking? = self.uses_deep_linking

  # True if suma should send receipts.
  # This should be false where the underlying provider takes care of sending receipts
  # (which usually means the provider is charging the member themselves).
  def send_receipts? = self.send_receipts

  def configure_trip_provider(key)
    self.uses_deep_linking = false
    self.trip_provider_key = key
    # For now, we can assume we're always sending receipts for MaaS integrations.
    self.send_receipts = true
    return self
  end

  def configure_deep_linking(send_receipts:)
    self.uses_deep_linking = true
    self.trip_provider_key = ""
    self.send_receipts = send_receipts
    return self
  end

  def anon_proxy_vendor_account_requires_attention?(member, now:)
    return false unless self.uses_deep_linking?
    account = self.find_anon_proxy_vendor_account(member)
    return true if account.nil?
    return account.auth_to_vendor.needs_attention?(now:)
  end

  # Find the anonymous proxy vendor account for the member
  # that satisfies this adapter (usually this means finding one for the right vendor).
  # It is ok to return nil if the account or vendor does not exist.
  # Should only be called if +uses_deep_linking+ is true;
  # otherwise, an exception is raised.
  #
  # @return [nil,Suma::AnonProxy::VendorAccount]
  def find_anon_proxy_vendor_account(member)
    Suma.assert { self.uses_deep_linking? }
    vendor = self.vendor_service.vendor
    configuration = Suma::AnonProxy::VendorConfiguration.where(vendor:)
    account = Suma::AnonProxy::VendorAccount.where(configuration:, member:)
    return account.first
  end

  def validate
    super
    if self.uses_deep_linking?
      errors.add(:trip_provider_key, "deeplinks do not use trip managers") unless trip_provider_key.blank?
    else
      validates_includes Suma::Mobility::TripProvider.registered_keys, :trip_provider_key
    end
  end
end
