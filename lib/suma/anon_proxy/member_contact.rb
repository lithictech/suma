# frozen_string_literal: true

require "suma/postgres"
require "suma/anon_proxy"

class Suma::AnonProxy::MemberContact < Suma::Postgres::Model(:anon_proxy_member_contacts)
  plugin :timestamps

  many_to_one :member, class: "Suma::Member"
  one_to_many :vendor_accounts, class: "Suma::AnonProxy::VendorAccount"

  def phone? = !!self.phone
  def email? = !!self.email
end
