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
    link_to_use = Suma::UrlShortener.enabled? ? Suma::UrlShortener.shortener.shorten(magic_link).url : magic_link
    vendor_account_message.vendor_account.replace_access_code(token, link_to_use).save_changes
    msg = Suma::Messages::SingleValue.new(
      "anon_proxy",
      "lime_deep_link_access_code",
      link_to_use,
    )
    vendor_account_message.vendor_account.member.message_preferences!.dispatch(msg)
    result.handled = true
    return result
  end
end
