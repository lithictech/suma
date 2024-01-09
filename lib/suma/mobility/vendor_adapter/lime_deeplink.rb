# frozen_string_literal: true

require "suma/lime"

require "suma/mobility/vendor_adapter/deeplink_mixin"

class Suma::Mobility::VendorAdapter::LimeDeeplink
  include Suma::Mobility::VendorAdapter::DeeplinkMixin
  include Suma::Mobility::VendorAdapter

  def _vendor_name = Suma::Lime::VENDOR_NAME
end
