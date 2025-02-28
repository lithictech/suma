# frozen_string_literal: true

require "suma/lyft/pass"

class Suma::AnonProxy::AuthToVendor::LyftPass < Suma::AnonProxy::AuthToVendor
  def auth
    return if self.vendor_account.registered_with_vendor.present?
    lp = Suma::Lyft::Pass.from_config
    lp.authenticate
    lp.invite_member(self.vendor_account.member)
    self.vendor_account.update(registered_with_vendor: Time.now.iso8601)
  end

  def need_polling? = false
  def needs_attention? = self.vendor_account.registered_with_vendor.blank?
end
