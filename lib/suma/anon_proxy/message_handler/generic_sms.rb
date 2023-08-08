# frozen_string_literal: true

require "suma/messages/generic_access_code"

class Suma::AnonProxy::MessageHandler::GenericSms < Suma::AnonProxy::MessageHandler
  ACCESS_CODE_REGEXES = [
    /Your (?<service>\w+) (?<_>login|access) code is (?<token>\d+)/,
  ].freeze

  def key = "generic_sms"

  def can_handle?(message)
    return ACCESS_CODE_REGEXES.any? { |re| re.match(message.content) }
  end

  # @param vendor_account_message [Suma::AnonProxy::VendorAccountMessage]
  # @return [Suma::Message::Delivery,nil]
  def handle(vendor_account_message)
    ACCESS_CODE_REGEXES.each do |re|
      m = re.match(vendor_account_message.message_content)
      next unless m
      token = m[:token]
      service = m[:service]
      member = vendor_account_message.vendor_account.member
      vendor_account_message.vendor_account.replace_access_code(token).save_changes
      msg = Suma::Messages::GenericAccessCode.new(member, service, token)
      return member.message_preferences!.dispatch(msg).first
    end
    raise "should not reach here (can_handle? was true, but was not handled in #handle)"
  end
end
