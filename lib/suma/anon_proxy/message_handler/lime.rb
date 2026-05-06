# frozen_string_literal: true

require "suma/messages/single_value"
require "suma/url_shortener"

class Suma::AnonProxy::MessageHandler::Lime < Suma::AnonProxy::MessageHandler
  def key = "lime"

  NOREPLY = "no-reply@li.me"

  def can_handle?(message)
    return message.from == NOREPLY
  end

  ACCESS_CODE_LINK_RE = %r{(https://limebike\.app\.link/login\?magic_link_token=)(\w+)}
  ACCESS_CODE_EMAIL_VERIFY_LINK_RE = %r{(https://limebike\.app\.link/email_verification\?authentication_code=)(\w+)}
  ACCESS_CODE_API_SIGNIN_RE = %r{(https://web-production\.lime\.bike/api/rider/v2/magic-challenge\?magic_link_token=)(\w+)}

  # @param vendor_account_message [Suma::AnonProxy::VendorAccountMessage]
  # @return [Suma::AnonProxy::MessageHandler::Result]
  def handle(vendor_account_message)
    result = Suma::AnonProxy::MessageHandler::Result.new
    magic_link = nil
    token = nil
    [ACCESS_CODE_LINK_RE, ACCESS_CODE_EMAIL_VERIFY_LINK_RE, ACCESS_CODE_API_SIGNIN_RE].each do |re|
      link_matchdata = re.match(vendor_account_message.message_content)
      next unless link_matchdata
      magic_link = link_matchdata[0]
      token = link_matchdata[2]
    end
    if magic_link.nil?
      result.handled = false
      return result
    end

    vendor_account = vendor_account_message.vendor_account
    if vendor_account.pending_closure
      # As of sometime in early 2026, we can no longer exchange the magic link token;
      # instead, it's supposed to be followed to a Cloudflare page,
      # then a link with a new token is issued, and users follow that.
      # So we need to log people out manually.
      # Update the magic link, so an admin can follow the link to login manually
      # (which will THEN trash the user's existing access).
      # Then the admin should use the external action to mark the account
      # as no longer pending closure, and removing the contact association,
      # which is what used to happen here.
      vendor_account.replace_access_code(token, magic_link)
      vendor_account.save_changes
      result.handled = true
      return result
    elsif Suma::Payment.service_usage_prohibited_reason(vendor_account.member.payment_account)
      # It is possible for a Lime user who is logged out to manually request a reset code link.
      # We normally can't tell apart requests that we make, from requests that they make;
      # and since there is usually no need to, we don't worry about it.
      # However, if we've logged them out due to non-payment, and they request a link
      # (which would only be done by a technically savvy, malicious user)
      # we do NOT want to send the code onto them. If we see this behavior,
      # report it to developers so we can take action. There may be nothing to do,
      # or we may want to reach out to ban the user from suma entirely.
      Sentry.capture_message("Prohibited Lime user requested access code") do |scope|
        scope.set_extras(
          vendor_account_id: vendor_account.id,
          vendor_configuration_id: vendor_account.configuration_id,
          member_name: vendor_account.member.name,
        )
      end
      result.handled = true
      return result
    end
    link_to_use = Suma::UrlShortener.enabled? ? Suma::UrlShortener.shortener.shorten(magic_link).short_url : magic_link
    vendor_account.replace_access_code(token, link_to_use).save_changes
    msg = Suma::Messages::SingleValue.new(
      "anon_proxy",
      "lime_deep_link_access_code",
      link_to_use,
    )
    vendor_account.member.message_preferences!.dispatch(msg)
    result.handled = true
    return result
  end
end
