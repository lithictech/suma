# frozen_string_literal: true

require "icalendar"
require "icalendar/recurrence"
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

  AndCode = Struct.new(:link, :code)

  class << self
    # The app URL where users can join the org (or get redirected to signup).
    def partner_signup_url = Suma.app_url + "/partner-signup"

    # @return [Suma::Organization::RegistrationLink]
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
    # @return [AndCode,nil]
    def and_code_from_params(h, at:)
      code = h.symbolize_keys[ONE_TIME_CODE_PARAM.to_sym]
      return nil unless code
      link = self.lookup_from_code(code, at:)
      return nil if link.nil?
      return AndCode.new(link, code)
    end
  end

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

  # Return true if any of the ical fields are set,
  # which indicates we should evaluate using the schedule.
  def use_schedule? = self.ical_dtstart || self.ical_dtend || self.ical_rrule.present?

  # Return a VEVENT string including fields which are set.
  # If tags is true, include BEGIN/END tags.
  def ical_vevent(tags: false)
    return [
      tags ? "BEGIN:VEVENT" : nil,
      self.ical_dtstart ? "DTSTART:#{self._icaltime(self.ical_dtstart)}" : nil,
      self.ical_dtend ? "DTEND:#{self._icaltime(self.ical_dtend)}" : nil,
      self.ical_rrule.present? ? "RRULE:#{self.ical_rrule}" : nil,
      tags ? "END:VEVENT" : nil,
    ].compact.join("\n")
  end

  def _icaltime(t) = t.utc.strftime("%Y%m%dT%H%M%SZ")

  # Return whether the given time is within the receiver's schedule.
  # If not using a schedule, return true.
  # If any schedule fields are set (ical start, end, rrule),
  # but not enough to process a schedule (start and end),
  # return false.
  # If the rrule is invalid, return false.
  # Otherwise return true if 'at' is during an occurrence.
  def within_schedule?(at)
    return true unless self.use_schedule?
    check = at.utc
    window = (check - 48.hours)..(check + 48.hours)
    avails = self.scheduled_availabilities(window:)
    ok = avails.any? do |occurrence|
      occurrence.start_time <= check && check < occurrence.end_time
    end
    return ok
  end

  # If using an ical event, return the available events during the window.
  # If not, return empty.
  # If RRULE is used and invalid, return empty.
  # @return [Array<Icalendar::Event>]
  def scheduled_availabilities(window: Time.now..1.month.from_now)
    return [] if self.ical_dtstart.nil? || self.ical_dtend.nil?
    event = Icalendar::Event.new
    event.dtstart = Icalendar::Values::DateTime.new(self.ical_dtstart)
    event.dtend = Icalendar::Values::DateTime.new(self.ical_dtend)
    event.rrule = Icalendar::Values::Recur.new(self.ical_rrule) if self.ical_rrule.present?
    begin
      result = event.occurrences_between(window.first, window.last)
    rescue ArgumentError => e
      return [] if e.to_s.include?("Invalid iCal rule component")
      raise e
    end
    return result
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
end
