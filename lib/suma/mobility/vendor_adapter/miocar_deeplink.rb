# frozen_string_literal: true

require "suma/lime"

require "suma/mobility/vendor_adapter/deeplink_mixin"

class Suma::Mobility::VendorAdapter::MiocarDeeplink
  include Suma::Mobility::VendorAdapter::DeeplinkMixin
  include Suma::Mobility::VendorAdapter

  def _vendor_name = "Miocar"
end
