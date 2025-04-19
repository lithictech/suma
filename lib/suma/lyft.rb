# frozen_string_literal: true

require "suma/mobility/gbfs"

require "suma/http"

module Suma::Lyft
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:lyft) do
    # ID of the Vendor to use for deeplinking into the Lyft app.
    setting :deeplink_vendor_slug, "lyft"

    setting :pass_authorization, ""
    setting :pass_email, ""
    setting :pass_org_id, ""
    setting :pass_vendor_slug, "lyft"
    setting :pass_vendor_service_rate_id, 0
  end

  # @return [Suma::Vendor]
  def self.deeplink_vendor
    return Suma.cached_get("lyft_deeplink_vendor") do
      Suma::Vendor.find!(slug: self.deeplink_vendor_slug)
    end
  end
end
