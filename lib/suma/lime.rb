# frozen_string_literal: true

require "suma/http"

module Suma::Lime
  include Appydays::Configurable
  include Appydays::Loggable

  UNCONFIGURED_AUTH_TOKEN = "get-from-lime-add-to-env"

  configurable(:lime) do
    setting :maas_auth_token, UNCONFIGURED_AUTH_TOKEN
    # Slug of the Vendor to use for deeplinking into the Lime app.
    setting :deeplink_vendor_slug, "lime"
    # Turn off the violations processor. We want to make sure we only run this on production,
    # even if other environments (like development) point towards the production email table.
    setting :violations_processor_enabled, false
    # Email where trip reports are sent from.
    setting :trip_report_from_email, "lime-trip-report-from-email@example.org"
    # Email where trip reports are sent to.
    setting :trip_report_to_email, "lime-trip-report-to-email@example.org"
  end

  # @return [Suma::Vendor]
  def self.deeplink_vendor
    return Suma.cached_get("lime_deeplink_vendor") do
      Suma::Vendor.find!(slug: self.deeplink_vendor_slug)
    end
  end
end
