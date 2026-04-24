# frozen_string_literal: true

require "icalendar"
require "rqrcode"

require "suma/admin_linked"
require "suma/postgres/model"

# Registration links are links (QR codes) that organizations can point users to;
# users who log in or register from this link are automatically verified members of the organization.
# An example use case would be a housing partner that wants residents to enroll at move-in;
# they can show the resident a QR code that will verify them automatically.
#
# == Risks and Mitigations
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
# - Calling ensure_verified_membership deletes the given one-time-code,
#   so it cannot be reused.
#
# == User flow
#
# Once the link is created, there is the following flow.
#
# - Users go to /api/v1/registration_links/<opaque_id>
# - Users get redirected to /api/v1/registration_links/capture?suma_regcode=<one time code>
#   - This param is stored by the Rack::UtmCapture middleware,
#     so is available to all future calls to the API.
# - Users finally get redirected to /app/partner-signup.
#   One of three situations are true:
# - 1) If the code is invalid/expired/used, or not within schedule, they are shown a page
#   that the link isn't valid.
# - 2) If there is no user, OR the current user is not onboarded,
#   we redirect back to the homepage.
#   - We've capture the suma_regcode already so it'll be available later.
#   - When we get the current user (which is used during onboardaing),
#     we include information about the registration code.
#   - Do not show the 'organization' dropdown if there is an active registration link.
#   - When submitting onboarding (/api/v1/me/update), if there is no organization name,
#     but there IS an active registration link (for the stored suma_regcode), ensure membership in that org.
# - 3) If there is an active user who is onboarded,
#   show them the option to accept the invitation to the organization,
#   or they can go their dashboard.
class Suma::Organization::RegistrationLink < Suma::Postgres::Model(:organization_registration_links)
  include Suma::AdminLinked
  include Suma::Postgres::HybridSearch

  ONE_TIME_CODE_PARAM = :suma_regcode

  configurable(:organization_registration_link) do
    setting :ttl, 60.minutes.to_i
  end

  plugin :hybrid_search
  plugin :timestamps
  plugin :translated_text, :intro, Suma::TranslatedText

  many_to_one :created_by, class: "Suma::Member"
  many_to_one :organization, class: "Suma::Organization"
  one_to_many :memberships, class: "Suma::Organization::Membership", key: :registration_link_id

  def initialize(*)
    super
    self[:opaque_id] ||= Suma::Secureid.new_opaque_id("rl")
  end

  # URL that points to this registration link.
  # If this link is valid, this URL will 302 to the "one time url."
  def durable_url = Suma.api_url + "/v1/registration_links/#{self.opaque_id}"

  def durable_url_qr_code_data_url(size: 120)
    qr = RQRCode::QRCode.new(self.durable_url)
    png = qr.as_png(size:)
    data_url = "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
    return data_url
  end

  # Store a one-time code in Redis, and return it.
  # @return [String]
  def make_one_time_code
    one_time_code = Suma::Secureid.rand_enc(12)
    Suma::Redis.durable.with do |c|
      c.call("SET", "regcode/#{one_time_code}", self.id.to_s, "EX", self.class.ttl)
    end
    return one_time_code
  end

  # Return the URL used to capture suma_regcode,
  # which then redirects onto partner_signup_url.
  # @param code [String] If nil, use make_one_time_code.
  def make_code_capture_url(code=nil)
    code ||= self.make_one_time_code
    return Suma.api_url + "/v1/registration_links/capture?#{ONE_TIME_CODE_PARAM}=#{code}"
  end

  class << self
    # The app URL where users can join the org (or get redirected to signup).
    def partner_signup_url = Suma.app_url + "/partner-signup"

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
    # Return an array of [code string, registration link].
    # Return nil if not present or the code is not valid.
    # @return [Array,nil]
    def from_params(h, at:)
      code = h.symbolize_keys[ONE_TIME_CODE_PARAM.to_sym]
      return nil unless code
      link = self.lookup_from_code(code, at:)
      return [code, link]
    end
  end

  def within_schedule?(at)
    vevent = self.ical_event
    return true if vevent.blank?
    raise Suma::InvariantViolation, "RegistrationLink.ical_event must begin with BEGIN:VEVENT, got #{vevent}" unless
      vevent.start_with?("BEGIN:VEVENT")
    calendar = self._parse_vevent_str(vevent)
    event = calendar.events.first
    Suma.assert { calendar.events.length === 1 }
    start_time = event.dtstart&.to_time&.utc
    end_time = event.dtend&.to_time&.utc
    return false if start_time.nil? || end_time.nil?
    check = at.utc
    return check >= start_time && check < end_time
  end

  def _parse_vevent_str(vevent)
    raise Suma::InvariantViolation, "ical_event must begin with BEGIN:VEVENT, got #{vevent}" unless
      vevent.start_with?("BEGIN:VEVENT")
    vevent = "BEGIN:VCALENDAR\nVERSION:2.0\n#{vevent}\nEND:VCALENDAR\n"
    p = Icalendar::Parser.new(vevent, true)
    begin
      c = p.parse
    rescue Icalendar::Parser::ParseError
      return nil
    end
    return c.first
  end

  # Set the ical event string.
  # We handle a bunch of heuristics to just extract the first VEVENT of a string.
  def ical_event=(s)
    s = s.strip
    if s.blank?
      self[:ical_event] = s
      return
    end
    if (calstart = _find_end(s, "BEGIN:VCALENDAR\n"))
      s.slice!(0, calstart)
    end
    if (calend = s.index("END:VCALENDAR"))
      s.slice!(calend, s.length)
    end
    if (evstart = _find_end(s, "BEGIN:VEVENT\n"))
      s.slice!(0, evstart)
    end
    if (evend = s.index("END:VEVENT"))
      s.slice!(evend, s.length)
    end
    s.strip!
    if s.blank?
      self[:ical_event] = s
      return
    end
    s.prepend("BEGIN:VEVENT\n")
    s << "\nEND:VEVENT\n"
    self[:ical_event] = s
  end

  def _find_end(s, substr)
    i = s.index(substr)
    return i && (i + substr.length)
  end

  # Ensure the member has a verified membership.
  # - If there is an unverified membership, verify it (update the Verification object if needed).
  # - If there is a verified membership, noop.
  # - Otherwise (no or former membership), create a new one.
  #
  # @param [Suma::Member] member
  # @param [String] code The one-time code. Is deleted after use.
  def ensure_verified_membership(member, code:)
    m = self._ensure_verified_membership(member, code)
    Suma::Redis.durable.with do |c|
      c.call("DEL", "regcode/#{code}")
    end
    return m
  end

  def _ensure_verified_membership(member, _code)
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

  def rel_admin_link = "/registration-link/#{self.id}"

  def hybrid_search_fields
    return [
      :organization,
    ]
  end

  def validate
    super
    errors.add(:ical_event, "not a valid VEVENT: #{self.ical_event}") if
      self.ical_event.present? && self._parse_vevent_str(self.ical_event).nil?
  end
end
