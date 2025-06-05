# frozen_string_literal: true

require "suma/simple_registry"

class Suma::AnonProxy::Relay
  extend Suma::SimpleRegistry

  class NoRecipient < StandardError; end

  # Return the way to identify the relay, like 'postmark' or 'twilio'.
  # @return [String]
  def key = raise NotImplementedError

  # Return :phone or :email
  # @return [:phone, :email]
  def transport = raise NotImplementedError

  # Every relay requires at least one way to process inbound messages.
  # If WebhookDB is used (see proxy-accounts.md), return the dataset.
  # This dataset can be limited to only relevant messages, if needed.
  def webhookdb_dataset = raise NotImplementedError

  # Provision an address in the provider.
  # For example, this can be generating an email address
  # that can be used to look up the user, or allocating a number in Twilio.
  #
  # @param member [Suma::Member]
  # @return [ProvisionedAddress]
  def provision(member) = raise NotImplementedError

  # @param addr [ProvisionedAddress]
  def deprovision(addr) = raise NotImplementedError

  # Array of {name:, url:} hashes for +Suma::ExternalLinks+.
  def external_links(_member_contact) = []

  class ProvisionedAddress
    attr_accessor :address, :external_id

    def initialize(address, external_id: nil)
      self.address = address
      self.external_id = external_id
    end
  end

  # Given a WebhookDB row from the integration associated with this relay,
  # return a +ParsedMessage+.
  # @return [ParsedMessage]
  def parse_message(_whdb_row) = raise NotImplementedError

  require_relative "relay/fake_email"
  register(FakeEmail.new.key, FakeEmail)

  require_relative "relay/fake_phone"
  register(FakePhone.new.key, FakePhone)

  require_relative "relay/postmark"
  register(Postmark.new.key, Postmark)

  require_relative "relay/signalwire"
  register(Signalwire.new.key, Signalwire)

  # @return [Suma::AnonProxy::Relay]
  def self.create!(key)
    return self.registry_create!(key)
  end

  # @return [String]
  def self.active_email_relay_key = Suma::AnonProxy.email_relay
  # @return [Suma::AnonProxy::Relay]
  def self.active_email_relay = self.create!(self.active_email_relay_key)

  # @return [String]
  def self.active_phone_relay_key = Suma::AnonProxy.phone_relay
  # @return [Suma::AnonProxy::Relay]
  def self.active_phone_relay = self.create!(self.active_phone_relay_key)
end
