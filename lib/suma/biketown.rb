# frozen_string_literal: true

module Suma::Biketown
  include Appydays::Configurable

  configurable(:biketown) do
    # ID of the Vendor to use for deeplinking into the Biketown app.
    setting :deeplink_vendor_slug, "biketown"
  end

  # @return [Suma::Vendor]
  def self.deeplink_vendor
    return Suma.cached_get("biketown_deeplink_vendor") do
      Suma::Vendor.find!(slug: self.deeplink_vendor_slug)
    end
  end
end
