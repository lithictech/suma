# frozen_string_literal: true

require "suma/messages/single_value"

class Suma::AnonProxy::MessageHandler::Lime < Suma::AnonProxy::MessageHandler
  def key = "lime"

  NOREPLY = "no-reply@li.me"

  def can_handle?(message)
    return message.from == NOREPLY
  end

  ACCESS_CODE_TOKEN_RE = %r{copy and paste this code:</\w+>\s*<\w+.*>(\w+)</\w+>}
  ACCESS_CODE_LINK_RE = %r{(https://limebike\.app\.link/login\?magic_link_token=\w+)}
  ACCESS_CODE_EMAIL_VERIFY_LINK_RE = %r{(https://limebike\.app\.link/email_verification\?authentication_code=\w+)}

  # @param vendor_account_message [Suma::AnonProxy::VendorAccountMessage]
  # @return [Suma::AnonProxy::MessageHandler::Result]
  def handle(vendor_account_message)
    result = Suma::AnonProxy::MessageHandler::Result.new
    unless (ac_token_match = ACCESS_CODE_TOKEN_RE.match(vendor_account_message.message_content))
      result.handled = false
      return result
    end
    token = ac_token_match[1]
    link_md = nil
    [ACCESS_CODE_LINK_RE, ACCESS_CODE_EMAIL_VERIFY_LINK_RE].each do |re|
      link_md = re.match(vendor_account_message.message_content)
      break if link_md
    end
    if link_md.nil?
      raise "Could not find a magic link in the message content: #{vendor_account_message.message_content}"
    end
    magic_link = link_md[1]
    vendor_account_message.vendor_account.replace_access_code(token, magic_link).save_changes
    msg = Suma::Messages::SingleValue.new(
      "anon_proxy",
      "lime-deep-link-access-code",
      magic_link,
    )
    vendor_account_message.vendor_account.member.message_preferences!.dispatch(msg)
    result.handled = true
    return result
  end
end
