# frozen_string_literal: true

class Suma::AnonProxy::AuthToVendor::Http < Suma::AnonProxy::AuthToVendor
  # Return the fields needed to make an auth request.
  def auth_request
    va = self.vendor_account
    body = va.configuration.auth_body_template % {email: va.contact_email, phone: va.contact_phone}
    raise KeyError, "configuration auth_url must be set" if
      (url = va.configuration.auth_url).blank?
    raise KeyError, "configuration auth_http_method must be set" if
      (http_method = va.configuration.auth_http_method).blank?
    return {
      url:,
      http_method:,
      headers: va.configuration.auth_headers.to_h,
      body:,
    }
  end

  def auth
    areq = self.auth_request
    Suma::Http.execute(
      areq.delete(:http_method).downcase.to_sym,
      areq.delete(:url),
      logger: self.vendor_account.logger,
      **areq,
    )
  end
end
