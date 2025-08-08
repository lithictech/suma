# frozen_string_literal: true

require "suma/http"

class Suma::AnonProxy::AuthToVendor::Lime < Suma::AnonProxy::AuthToVendor
  class NoToken < Suma::Http::Error; end

  AGREEMENT_PARAMS = {user_agreement_version: "5", user_agreement_country_code: "US"}.freeze
  USER_AGENT = "Android Lime/3.219.0; (com.limebike; build:3.219.0; Android 33) 4.12.0"
  APP_VERSION = "3.219.0"

  def request_headers
    return {
      "X-Suma" => "holá",
      "Platform" => "Android",
      "User-Agent" => USER_AGENT,
      "App-Version" => APP_VERSION,
      # Best we can tell, these do not matter/do not need to be valid.
      # It's possible this will change in the future.
      "X-Device-Token" => "e3001a2a-ef16-4201-a473-af7d9fd47735",
      "X-Fingerprint" => "3820d768a6525588",
      "X-Session-ID" => "1751641417301",
    }
  end

  def auth(*)
    contact = self.vendor_account.ensure_anonymous_contact(:email)
    Suma::Http.post(
      "https://web-production.lime.bike/api/rider/v2/onboarding/magic-link",
      AGREEMENT_PARAMS.merge(email: contact.email),
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
        **self.request_headers,
      },
      logger: self.vendor_account.logger,
    )
  end

  # Given a magic link token, return an auth token.
  def exchange_magic_link_token(magic_link_token)
    resp = Suma::Http.post(
      "https://web-production.lime.bike/api/rider/v2/onboarding/login",
      AGREEMENT_PARAMS.merge(magic_link_token: magic_link_token, has_virtual_card: false),
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
        **self.request_headers,
      },
      logger: self.vendor_account.logger,
    )
    # Not sure why yet but we can get 200s without a token when making many requests.
    raise NoToken, resp unless resp.parsed_response.key?("token")
    return resp.parsed_response.fetch("token")
  end

  def log_out(auth_token)
    Suma::Http.post(
      "https://web-production.lime.bike/api/rider/v1/logout",
      headers: {
        "Authorization" => "Bearer #{auth_token}",
        "Content-Type" => "application/x-www-form-urlencoded",
        **self.request_headers,
      },
      logger: self.vendor_account.logger,
    )
  end

  def needs_polling? = true
  def needs_attention?(*) = self.vendor_account.contact.nil?
end
