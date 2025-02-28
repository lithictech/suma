# frozen_string_literal: true

class Suma::AnonProxy::AuthToVendor::Lime < Suma::AnonProxy::AuthToVendor
  def auth
    contact = self.ensure_anonymous_email_contact
    Suma::Http.post(
      "https://web-production.lime.bike/api/rider/v2/onboarding/magic-link",
      "email=#{contact.email}&user_agreement_version=5&user_agreement_country_code=US",
      headers: {
        "X-Suma" => "holá",
        "Platform" => "Android",
        "User-Agent" => "Android Lime/3.179.1; (com.limebike; build:3.179.1; Android 33) 4.10.0",
        "App-Version" => "3.179.1",
        "Content-Type" => "application/x-www-form-urlencoded",
      },
      logger: self.vendor_account.logger,
    )
  end

  def need_polling? = true
  def needs_attention? = self.vendor_account.contact.nil?
end
