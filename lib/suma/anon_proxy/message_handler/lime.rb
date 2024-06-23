# frozen_string_literal: true

require "suma/messages/single_value"

class Suma::AnonProxy::MessageHandler::Lime < Suma::AnonProxy::MessageHandler
  def key = "lime"

  NOREPLY = "no-reply@li.me"

  def can_handle?(message)
    return message.from == NOREPLY
  end

  ACCESS_CODE_TOKEN_RE = /magic_link_token=(\w+)/
  ACCESS_CODE_LINK_RE = %r{(https://web-production\.lime\.bike/api/rider/v2/magic-challenge\?magic_link_token=\w+)}

  # @param vendor_account_message [Suma::AnonProxy::VendorAccountMessage]
  # @return [Suma::AnonProxy::MessageHandler::Result]
  def handle(vendor_account_message)
    result = Suma::AnonProxy::MessageHandler::Result.new
    unless (ac_token_match = ACCESS_CODE_TOKEN_RE.match(vendor_account_message.message_content))
      result.handled = false
      return result
    end
    unless (link_md = ACCESS_CODE_LINK_RE.match(vendor_account_message.message_content))
      raise "Could not find a magic link in the message content: #{vendor_account_message.message_content}"
    end
    token = ac_token_match[1]
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
