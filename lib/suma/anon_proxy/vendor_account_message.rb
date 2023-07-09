# frozen_string_literal: true

require "suma/postgres"
require "suma/anon_proxy"

class Suma::AnonProxy::VendorAccountMessage < Suma::Postgres::Model(:anon_proxy_vendor_account_messages)
  plugin :timestamps

  many_to_one :vendor_account, class: "Suma::AnonProxy::VendorAccount"
  many_to_one :outbound_delivery, class: "Suma::Message::Delivery"
end
