# frozen_string_literal: true

require "suma/lyft"
require "appydays/loggable"

# Integrates with the Lyft Pass (Business) system.
# Can log into Lyft using the configured username, find the auth token in the sent email,
# then exchange it for an access code to hit the API.
# From the API, we find all rides taken for the configured program
class Suma::Lyft::Pass
  include Appydays::Loggable

  CREDENTIAL_SERVICE = "lyft-pass-access-token"
  # Credentials that expire before this far from now,
  # should be thrown out for a new credential.
  EXPIRES_AT_FUZZ = 30.minutes

  class << self
    def from_config
      return self.new(
        email: Suma::Lyft.pass_email,
        authorization: Suma::Lyft.pass_authorization,
        org_id: Suma::Lyft.pass_org_id,
        program_id: Suma::Lyft.pass_program_id,
        vendor_service_rate: Suma::Vendor::ServiceRate.find!(Suma::Lyft.pass_vendor_service_rate_id),
      )
    end
  end

  # After +authenticate+ is called, credential will be a valid credential.
  # @return [Suma::ExternalCredential]
  attr_reader :credential

  # Email for the Business account.
  # It will be logged in remotely, it is suggested to create a separate user account for this programmatic access.
  attr_reader :email

  # This is the Authorization header value in Lyft requests.
  # Get from the browser console during the authentication flow.
  # It's like "Basic d0dldWh2RF5MNmNwOllicHpWdnN0Y2E1UW1NTWVlUVJ2dnI1ZUl0UTI5S1JR"
  attr_reader :authorization

  # The Lyft org ID.
  # Go to https://business.lyft.com/organization/mysumaorg/lyft-pass/transactions,
  # then look for the request to https://www.lyft.com/v1/enterprise-insights/search/transactions
  # in the console. Grab the organization id from the query params.
  attr_reader :org_id

  # The lyft program (account) ID.
  # Grab it from the body of the GraphQL request to https://www.lyft.com/v1/enterprise-insights/search/transactions.
  # Or you can go to https://business.lyft.com/organization/mysumaorg/lyft-pass/transactions,
  # select the Program, and grab the ID from the accountId query param.
  attr_reader :program_id

  # @return [Suma::Vendor::ServiceRate]
  attr_reader :vendor_service_rate

  def initialize(email:, authorization:, org_id:, program_id:, vendor_service_rate:)
    raise ArgumentError, "email cannot be blank" if email.blank?
    raise ArgumentError, "authorization cannot be blank" if authorization.blank?
    raise ArgumentError, "org_id cannot be blank" if org_id.blank?
    raise ArgumentError, "program_id cannot be blank" if program_id.blank?
    raise ArgumentError, "vendor_service_rate cannot be nil" if vendor_service_rate.nil?
    @email = email
    @org_id = org_id
    @vendor_service_rate = vendor_service_rate
    @program_id = program_id
    @vendor_service = Suma::Vendor::Service.where(
      vendor: Suma::Lyft.mobility_vendor,
      mobility_vendor_adapter_key: "lyft_deeplink",
    ).first or
      raise Suma::InvalidPrecondition, "No mobility vendor service for Lyft vendor and configured rate"
    # No idea what this actually is, if it changes, etc.
    @authorization = authorization
    @credential = nil
  end

  # @return [Suma::ExternalCredential,nil]
  def find_credential
    return Suma::ExternalCredential.
        where(service: CREDENTIAL_SERVICE).
        where { expires_at > Time.now + EXPIRES_AT_FUZZ }.
        first
  end

  # @return [Suma::ExternalCredential]
  def authenticate
    @credential = self.find_credential || self.authenticate!
    return @credential
  end

  def debug(_resp)
    # puts resp.headers, resp.body
  end

  # @return [Suma::ExternalCredential]
  def authenticate!
    auth_started_at = Time.now - 5.seconds # 5 seconds for clock drift
    # Arrive at the webpage that prompts for your email
    login_get_resp = Suma::Http.get("https://account.lyft.com/auth/email", logger: nil)
    self.debug(login_get_resp)
    session_id = extract_cookie(login_get_resp, "sessId")

    # The JS on the login page starts the oauth process and gets a short-lived auth code
    auth_code_resp = Suma::Http.post(
      "https://api.lyft.com/oauth2/access_token",
      {grant_type: "client_credentials"},
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Cookie" => "sessId=#{session_id}",
        "Authorization" => @authorization,
        "X-Authorization" => @authorization,
      },
      logger: self.logger,
    )
    self.debug(auth_code_resp)
    lyft_access_token_cookie = extract_cookie(auth_code_resp, "lyftAccessToken")
    browser_id_cookie = extract_cookie(auth_code_resp, "stickyLyftBrowserId")

    # Submit the form, which sends an email
    submit_email_form_resp = Suma::Http.post(
      "https://api.lyft.com/v1/email/login/request",
      {
        email: @email,
        next_url: "https://www.lyft.com/business/login?login_session_uuid=#{session_id}",
        login_session_uuid: session_id,
      },
      headers: {
        "Cookie" => encode_cookies(
          sessId: session_id,
          lyftAccessToken: lyft_access_token_cookie,
          NEXT_LOCALE: "en-US",
          stickyLyftBrowserId: browser_id_cookie,
        ),
      },
      logger: self.logger,
    )
    self.debug(submit_email_form_resp)

    # Wait a bit for the email to arrive
    seconds_to_wait = 120
    sleep_interval = 2
    attempts_remaining = seconds_to_wait / sleep_interval
    auth_email_row = loop do
      attempts_remaining -= 1
      row = Suma::Webhookdb.postmark_inbound_messages_dataset.
        where(from_email: "business@identity.lyftmail.com", to_email: @email).
        where(subject: "Here's your one-time Lyft Business log-in link").
        where { timestamp > auth_started_at }.
        order(:timestamp).
        last
      break row if row
      raise Suma::InvalidPostcondition, "lyft never sent the email" if attempts_remaining.zero?
      Kernel.sleep(sleep_interval)
      self.logger.debug("waiting_for_lyft_to_send_email", attempts_remaining:)
    end
    # login_link = %r{"(https://account\.lyft\.com/auth/email\?et=.*)" style}.match(auth_email_row[:data].fetch('HtmlBody'))[1]
    # Extract the 'email token' ('et' query param) from the magic link.
    email_html = auth_email_row[:data].fetch("HtmlBody")
    email_token = %r{"https://account\.lyft\.com/auth/email\?et=([\w%_-]+)[&;]}.match(email_html)[1]
    email_token = URI.decode_uri_component(email_token)

    # Use the email token, session id, browser id, and auth code to request a long-lived access token
    access_token_resp = Suma::Http.post(
      "https://api.lyft.com/oauth2/access_token",
      {
        grant_type: "urn:lyft:oauth2:grant_type:email",
        email_token:,
        login_session_uuid: session_id,
      },
      headers: {
        "Authorization" => @authorization,
        "X-Authorization" => @authorization,
        "Content-Type" => "application/x-www-form-urlencoded",
        "Cookie" => encode_cookies(
          sessId: session_id,
          lyftAccessToken: lyft_access_token_cookie,
          stickyLyftBrowserId: browser_id_cookie,
        ),
      },
      logger: self.logger,
    )
    self.debug(access_token_resp)
    access_token = extract_cookie(access_token_resp, "lyftAccessToken")
    data = {
      body: access_token_resp.parsed_response,
      cookies: {
        sessId: session_id,
        lyftAccessToken: access_token,
        stickyLyftBrowserId: browser_id_cookie,
      },
    }
    # noinspection RubyArgCount
    updated_credential = Suma::ExternalCredential.new(
      service: CREDENTIAL_SERVICE,
      expires_at: Time.now + access_token_resp.parsed_response.fetch("expires_in"),
      data: data.to_json,
    ).insert_conflict(
      target: :service,
      update: {
        expires_at: Sequel[:excluded][:expires_at],
        data: Sequel[:excluded][:data],
      },
    )
    updated_credential.save_changes
    @credential = updated_credential
    return updated_credential
  end

  def auth_headers
    raise Suma::InvalidPrecondition, "must call authenticate" if @credential.nil?
    data = JSON.parse(@credential.data)
    h = {
      "Cookie" => encode_cookies(data.fetch("cookies")),
      "Origin" => "https://business.lyft.com",
      "Referer" => "https://business.lyft.com",
    }
    return h
  end

  def fetch_rides
    rides_resp = Suma::Http.post(
      "https://www.lyft.com/v1/enterprise-insights/search/transactions?organization_id=#{@org_id}&start_time=1546300800000",
      {
        "size" => 50,
        "next_token" => "",
        "aggs" => nil,
        "query" => {
          "bool" => {
            "must" => [
              {"nested" => {
                "path" => "transactions",
                "query" => {
                  "bool" => {
                    "should" => {
                      "terms" => {
                        "transactions.account_id" => [@program_id],
                      },
                    },
                  },
                },
              }},
            ],
          },
        },
        "include" => [
          "enterprise_product_type",
          "transportation_id",
          "transportation_type",
          "transportation_sub_type",
          "transportation_mode",
          "transactions.amount",
          "transactions.currency",
          "transactions.id",
          "transactions.transaction_type",
          "transactions.txn_reporting_timestamp",
          "requested_at_iso",
          "requested_at_iso[utc_offset]",
          "canceled_at_iso",
          "picked_up_at_iso",
          "dropped_off_at_iso",
          "user_full_name",
        ],
        "sort" => [{"requested_at_utc" => {"order" => "desc"}}],
      },
      headers: self.auth_headers,
      logger: self.logger,
    )
    return rides_resp.parsed_response
  end

  def fetch_ride(tx_id)
    resp = Suma::Http.get(
      "https://www.lyft.com/v1/enterprise-insights/detail/transactions-legacy/#{tx_id}",
      headers: self.auth_headers,
      logger: self.logger,
    )
    return resp.parsed_response
  end

  def sync_trips
    rides = self.fetch_rides
    tx_ids = rides.fetch("results").map { |r| r["transactions.id"] }
    tx_ids.each do |txid|
      ride = self.fetch_ride(txid)
      self.upsert_ride_as_trip(ride)
    end
  end

  def upsert_ride_as_trip(ride_resp)
    ride = ride_resp.fetch("ride")
    rider_phone = ride.fetch("rider").fetch("phone_number")
    ride_id = ride.fetch("ride_id")
    if (member = Suma::Member.with_normalized_phone(rider_phone.delete_prefix("+"))).nil?
      self.logger.warn("no_member_for_rider", ride_id:, rider_phone:)
      return nil
    end
    member.db.transaction(savepoint: true) do
      begin
        trip = Suma::Mobility::Trip.start_trip(
          member:,
          vehicle_id: ride_id,
          vendor_service: @vendor_service,
          rate: @vendor_service_rate,
          lat: 0,
          lng: 0,
          at: Time.at(ride.fetch("pickup").fetch("timestamp_ms") / 1000),
          # Set this to ensure the ride shows as ended and doesn't hit a unique constraint
          # on the active trip.
          ended_at: Time.at(ride.fetch("dropoff").fetch("timestamp_ms") / 1000),
          end_lat: 0,
          end_lng: 0,
          external_trip_id: ride_id,
        )
      rescue Sequel::UniqueConstraintViolation
        self.logger.debug("ride_already_exists", ride_id:)
        raise Sequel::Rollback
      end

      charge = trip.end_trip(lat: 0, lng: 0, adapter_kw: {ride_response: ride_resp})
      ride.fetch("line_items").each do |li|
        charge.add_off_platform_line_item(
          amount: self._money2money(li),
          memo: Suma::TranslatedText.create(all: li.fetch("title")),
        )
      end
      return charge
    end
  end

  def _money2money(h)
    money = h.fetch("money")
    return Money.new(money.fetch("amount"), money.fetch("currency"))
  end

  def extract_cookie(resp, key)
    return %r{#{key}=([\w\-/\+\=]+);}.match(resp.headers["Set-Cookie"])[1]
  end

  def encode_cookies(h)
    return h.map { |k, v| "#{k}=#{v}" }.join("; ")
  end
end
