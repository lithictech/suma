# frozen_string_literal: true

require "suma/lyft"
require "appydays/loggable"

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
        account_id: Suma::Lyft.pass_account_id,
      )
    end
  end

  attr_reader :credential

  def initialize(email:, authorization:, org_id:, account_id:)
    @email = email
    @org_id = org_id
    # No idea where this is coming from yet
    @authorization = authorization
    @account_id = account_id
    @credential = nil
  end

  def find_credential
    return Suma::ExternalCredential.
        where(service: CREDENTIAL_SERVICE).
        where { expires_at > Time.now + EXPIRES_AT_FUZZ }.
        first
  end

  def authenticate
    @credential = find_credential
    return if @credential
    self.authenticate!
  end

  def debug(_resp)
    # puts resp.headers, resp.body
  end

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
                        "transactions.account_id" => [@account_id],
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

  def extract_cookie(resp, key)
    return %r{#{key}=([\w\-/\+\=]+);}.match(resp.headers["Set-Cookie"])[1]
  end

  def encode_cookies(h)
    return h.map { |k, v| "#{k}=#{v}" }.join("; ")
  end
end
