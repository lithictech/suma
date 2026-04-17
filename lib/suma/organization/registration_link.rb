# frozen_string_literal: true

require "icalendar"

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

  ONE_TIME_CODE_PARAM = :suma_regcode

  configurable(:organization_registration_link) do
    setting :ttl, 15 * 60
  end

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :organization, class: "Suma::Organization"
  one_to_many :memberships, class: "Suma::Organization::Membership", key: :registration_link_id

  def initialize(*)
    super
    self[:opaque_id] ||= Suma::Secureid.new_opaque_id("rl")
  end

  # URL that points to this registration link.
  # If this link is valid, this URL will 302 to the "one time url."
  def durable_url = Suma.api_url + "/registration_links/#{self.opaque_id}"

  # Store a one-time code in Redis, and return it.
  # @return [String]
  def set_one_time_code
    one_time_code = Suma::Secureid.rand_enc(12)
    Suma::Redis.durable.with do |c|
      c.call("SET", "regcode/#{one_time_code}", self.id.to_s, "EX", self.class.ttl)
    end
    return one_time_code
  end

  # Return the URL to the link used to sign up,
  # with a query param that gets captured by the UtmCapture middleware,
  # and can fetch the associated link through ::from_params.
  # @param code [String] If nil, use set_one_time_code.
  def make_one_time_url(code=nil)
    code ||= self.set_one_time_code
    return Suma.app_url + "/partner/#{self.organization.id}?#{ONE_TIME_CODE_PARAM}=#{code}"
  end

  class << self
    def lookup_from_code(one_time_code, at:)
      link_id = Suma::Redis.durable.with do |c|
        c.call("GET", "regcode/#{one_time_code}")
      end
      return nil if link_id.nil?
      link = self[link_id]
      return nil if link.nil?
      return nil unless link.within_schedule?(at)
      return link
    end

    # Lookup an instance from the one-time-code in query params.
    # Return nil if not present or the code is not valid.
    def from_params(h, at:)
      code = h.symbolize_keys[ONE_TIME_CODE_PARAM.to_sym]
      return nil unless code
      link = self.lookup_from_code(code, at:)
      return link
    end
  end

  def within_schedule?(at)
    vevent = self.ical_event
    return true if vevent.blank?
    raise Suma::InvariantViolation, "RegistrationLink.ical_vevent must begin with BEGIN:VEVENT, got #{vevent}" unless
      vevent.start_with?("BEGIN:VEVENT")
    vevent = "BEGIN:VCALENDAR\nVERSION:2.0\n#{vevent}\nEND:VCALENDAR\n"
    calendars = Icalendar::Calendar.parse(vevent)
    event = calendars.first.events.first
    Suma.assert { calendars.first.events.length === 1 }
    start_time = event.dtstart.to_time.utc
    end_time = event.dtend.to_time.utc
    check = at.utc
    return check >= start_time && check < end_time
  end

  # Ensure the member has a verified membership.
  # - If there is an unverified membership, verify it (update the Verification object if needed).
  # - If there is a verified membership, noop.
  # - Otherwise (no or former membership), create a new one.
  def ensure_verified_membership(member)
    existing = Suma::Organization::Membership[member:, verified_organization: self.organization]
    return existing if existing
    unverified = Suma::Organization::Membership[member:, unverified_organization_name: self.organization.name]
    if unverified
      unverified.db.transaction do
        unverified.update(verified_organization: self.organization, registration_link: self)
        unverified.verification&.process(:approve)
      end
      return unverified
    end
    membership = Suma::Organization::Membership.create(
      member:, verified_organization: self.organization, registration_link: self,
    )
    return membership
  end

  def rel_admin_link = "/registration_link/#{self.id}"

  def hybrid_search_fields
    return [
      :organization,
    ]
  end
end
