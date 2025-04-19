# frozen_string_literal: true

require "suma/biketown"
require_relative "lyft_deeplink"

class Suma::Mobility::VendorAdapter::BiketownDeeplink < Suma::Mobility::VendorAdapter::LyftDeeplink
  protected def deeplink_vendor = Suma::Biketown.deeplink_vendor
end
