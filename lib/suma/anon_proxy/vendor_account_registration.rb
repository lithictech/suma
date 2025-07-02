# frozen_string_literal: true

require "suma/postgres"
require "suma/anon_proxy"

class Suma::AnonProxy::VendorAccountRegistration < Suma::Postgres::Model(:anon_proxy_vendor_account_registrations)
  plugin :timestamps

  many_to_one :account, class: "Suma::AnonProxy::VendorAccount"
end
