# frozen_string_literal: true

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
  # @return [Suma::Message::Delivery,nil]
  def handle(vendor_account_message)
    ac_token_match = ACCESS_CODE_TOKEN_RE.match(vendor_account_message.message_content)
    return nil unless ac_token_match
    token = ac_token_match[1]
    link_md = nil
    [ACCESS_CODE_LINK_RE, ACCESS_CODE_EMAIL_VERIFY_LINK_RE].each do |re|
      link_md = re.match(vendor_account_message.message_content)
      break if link_md
    end
    if link_md.nil?
      raise "Could not find a magic link in the message content: #{vendor_account_message.message_content}"
    end
    member = vendor_account_message.vendor_account.member
    vendor_account_message.vendor_account.replace_access_code(token).save_changes
    msg = Suma::Messages::LimeAccessCode.new(member, link_md[1], token)
    return member.message_preferences!.dispatch(msg).first
  end
end
