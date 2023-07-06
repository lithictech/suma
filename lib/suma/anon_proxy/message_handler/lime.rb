# frozen_string_literal: true

require "suma/messages/lime_access_code"

class Suma::AnonProxy::MessageHandler::Lime < Suma::AnonProxy::MessageHandler
  def key = "lime"

  NOREPLY = "no-reply@li.me"

  def can_handle?(message)
    return message.from == NOREPLY
  end

  ACCESS_CODE_RE = %r{copy and paste this code:</\w+>\s*<\w+.*>(\w+)</\w+>}

  # @param vendor_account_message [Suma::AnonProxy::VendorAccountMessage]
  # @return [Suma::Message::Delivery,nil]
  def handle(vendor_account_message)
    match = ACCESS_CODE_RE.match(vendor_account_message.message_content)
    return nil unless match
    token = match[1]
    member = vendor_account_message.vendor_account.member
    msg = Suma::Messages::LimeAccessCode.new(member, token)
    return member.message_preferences!.dispatch(msg).first
  end
end
