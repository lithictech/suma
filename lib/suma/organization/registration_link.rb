# frozen_string_literal: true

require "suma/admin_linked"
require "suma/postgres/model"

# Registration links are links (QR codes) that organizations can point users to;
# users who log in or register from this link are automatically verified members of the organization.
# An example use case would be a housing partner that wants residents to enroll at move-in;
# they can show the resident a QR code that will verify them automatically.
#
# This sort of automatic verification has nontrivial risks involved,
# especially around unauthorized sharing of the link.
# Many partners will print out the registration link,
# so it cannot be generated on-demand.
#
# We have a few mitigations in place:
#
# - The link has a schedule (RRULE) associated with it.
#   This can be used to set a rule allowing usage only during certain hours.
# - While the QR code link is long-lived, going to it redirects to a single-use token.
#   This will remove the long-lived code from browser history,
#   making it harder to share without having physical access to the QR code.
#
class Suma::Organization::RegistrationLink < Suma::Postgres::Model(:organization_registration_links)
  include Suma::AdminLinked
  include Suma::Postgres::HybridSearch

  ONE_TIME_CODE_PARAM = "suma_regcode"

  configurable(:organization_registration_link) do
    setting :ttl, 15 * 60
  end

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :organization, class: "Suma::Organization"
  one_to_many :memberships, class: "Suma::Organization::Membership"

  def registration_url = Suma.app_url + "/register-code/make/#{self.opaque_id}"

  # Return the URL to the partner jump page, with a UTM code that is captured
  def make_one_time_url
    one_time_code = Suma::Secureid.rand_enc(12)
    Suma::Redis.durable.with do |c|
      c.call("SET", "regcode/#{one_time_code}", self.id.to_s, self.class.ttl)
    end
    return Suma.app_url + "/partner/#{self.organization.id}?#{ONE_TIME_CODE_PARAM}=#{one_time_code}"
  end

  class << self
    def lookup_one_time_code(one_time_code)
      link_id = Suma::Redis.durable.with do |c|
        c.call("GET", "regcode/#{one_time_code}")
      end
      return nil if link_id.nil?
      return self[link_id]
    end
  end

  def rel_admin_link = "/registration_link/#{self.id}"

  def hybrid_search_fields
    return [
      :organization,
    ]
  end
end
