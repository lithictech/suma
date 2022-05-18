# frozen_string_literal: true

require "appydays/configurable"

module Suma::Plaid
  include Appydays::Configurable

  configurable(:plaid) do
    setting :client_id, "plaidclientid"
    setting :secret, "plaidsecret"
    setting :host, "https://sandbox.plaid.com"
    setting :app_url, "https://dashboard.plaid.com"
    setting :sync_institutions, false
    setting :bulk_sync_sleep, 1
    setting :supported_country_codes, ["US"], convert: ->(s) { s.split }
  end
end
