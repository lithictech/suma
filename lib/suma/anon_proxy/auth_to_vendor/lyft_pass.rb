# frozen_string_literal: true

require "suma/lyft/pass"

class Suma::AnonProxy::AuthToVendor::LyftPass < Suma::AnonProxy::AuthToVendor
  def auth
    lp = Suma::Lyft::Pass.from_config
    lp.authenticate
    lp.invite_member(self.vendor_account.member)
  end
end
