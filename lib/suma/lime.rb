# frozen_string_literal: true

require "suma/http"

module Suma::Lime
  include Appydays::Configurable
  include Appydays::Loggable

  UNCONFIGURED_AUTH_TOKEN = "get-from-lime-add-to-env"

  configurable(:lime) do
    setting :maas_auth_token, UNCONFIGURED_AUTH_TOKEN
    # Turn off the violations processor. We want to make sure we only run this on production,
    # even if other environments (like development) point towards the production email table.
    setting :violations_processor_enabled, false

    # Sync trips via email. In general, enable this OR the lime report sync;
    # do not do both, or we could double-charge members for trips.
    setting :trip_email_sync_enabled, false
    # See +trip_email_sync_enabled+.
    setting :trip_report_sync_enabled, false

    # The ID of the vendor configuration used to 'namespace' vendor accounts for trip reports.
    # That is, for emails appearing in the Lime trip report, only those VendorAccountRegistrations with emails
    # matching those, *and* belonging to this vendor accounts pointing to this configuration, are used.
    setting :trip_report_vendor_configuration_id, 0
    # Email where trip reports are sent from.
    # This can be an ILIKE statement, allowing multiple people to send emails during testing.
    setting :trip_report_from_email, "lime-trip-report-from-email@example.org"
    # Email where trip reports are sent to.
    setting :trip_report_to_email, "lime-trip-report-to-email@example.org"
  end
end
