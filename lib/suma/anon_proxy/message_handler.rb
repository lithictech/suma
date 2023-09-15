# frozen_string_literal: true

require "appydays/loggable"

require "suma/simple_registry"

class Suma::AnonProxy::MessageHandler
  include Appydays::Loggable
  extend Suma::SimpleRegistry

  OLD_MESSAGE_CUTOFF = 5.minutes

  class Result < Suma::TypedStruct
    # @!attribute handled [TrueClass,FalseClass]
    attr_accessor :handled
    # @!attribute handled [Suma::Message::Delivery]
    attr_accessor :outbound_delivery
  end

  # @return [String]
  def key = raise NotImplementedError

  # Return true if this message can be handled by the handler.
  # Often this involves checking the sender address (message.parsed.from).
  # @param parsed_message [Suma::AnonProxy::ParsedMessage]
  # @return [TrueClass,FalseClass]
  def can_handle?(parsed_message) = raise NotImplementedError

  # Handle the message, like by extracting useful info and sending an SMS.
  # In some cases (like marketing messages), this can be a noop.
  # Return a +Result+, which may involve sending a +Suma::Message::Delivery+
  # (which gets associated with the VendorAccountMessage).
  # It may also just take some other action, like updating a database object.
  # If the operation noops, +Result#handled+ is set to +false+.
  #
  # @param vendor_account_message [Suma::AnonProxy::VendorAccountMessage]
  # @return [Result]
  def handle(vendor_account_message) = raise NotImplementedError

  # After the relay parses the message,
  # handle it according to who sent it.
  #
  # For example, messages from 'no-reply@li.me' are handed off to AnonProxy::MessageHandler::Lime.
  #
  # Return the vendor account message that was sent, or nil.
  #
  # @param relay [Suma::AnonProxy::Relay] Relay used to parse the message.
  # @param message [Suma::AnonProxy::ParsedMessage]
  # @return [Suma::AnonProxy::VendorAccountMessage,nil]
  def self.handle(relay, message)
    return nil if message.timestamp < OLD_MESSAGE_CUTOFF.ago
    handler = self.registry.values.map(&:new).find { |h| h.can_handle?(message) }
    if handler.nil?
      self.logger.warn("no_handler_for_message", message:)
      return nil
    end
    vendor_account = Suma::AnonProxy::VendorAccount.where(
      configuration: Suma::AnonProxy::VendorConfiguration.where(message_handler_key: handler.key),
      contact: Suma::AnonProxy::MemberContact.where(relay_key: relay.key, relay.transport => message.to),
    ).first
    if vendor_account.nil?
      self.logger.warn("no_vendor_account_for_message", message:, relay: relay.key)
      return nil
    end

    vendor_account.db.transaction do
      vam = Suma::AnonProxy::VendorAccountMessage.new(
        message_id: message.message_id,
        message_from: message.from,
        message_to: message.to,
        message_content: message.content,
        message_timestamp: message.timestamp,
        relay_key: relay.key,
        message_handler_key: handler.key,
        vendor_account:,
      )
      result = handler.handle(vam)
      raise TypeError, "#{handler}#handle must return a Result" unless result.is_a?(Result)
      return nil unless result.handled
      vam.outbound_delivery = result.outbound_delivery
      vam.save_changes
      self.logger.info("anon_proxy_message_handled",
                       relay: relay.key,
                       member_id: vendor_account.member_id,
                       handler: handler.key,)
      return vam
    end
  end

  #   def extract_message(whdb_row, contact_optional: false)
  #     parsed_message = self.parse_message(whdb_row)
  #     mc_criteria = {relay_key: self.key, self.transport => parsed_message.to}
  #     member_contact = Suma::AnonProxy::MemberContact[mc_criteria]
  #     raise NoRecipient, "cannot find MemberContact using #{mc_criteria}" if member_contact.nil? && !contact_optional
  #     return Suma::AnonProxy::RelayedMessage.new(parsed_message:, relay: self, member_contact:)
  #   end

  require_relative "message_handler/fake"
  register(Fake.new.key, Fake)
  require_relative "message_handler/lime"
  register(Lime.new.key, Lime)

  # @return [Suma::AnonProxy::MessageHandler]
  def self.create!(key)
    return self.registry_create!(key)
  end
end
