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
  # If WebhookDB is used (see proxy-accounts.md), return the table name.
  def webhookdb_table = raise NotImplementedError

  # Provision an address in the provider.
  # For example, this can be generating an email address
  # that can be used to look up the user, or allocating a number in Twilio.
  #
  # @param [Suma::Member]
  # @return [String]
  def provision(_member) = raise NotImplementedError

  # Given a WebhookDB row from the integration associated with this relay,
  # return a +ParsedMessage+.
  # @return [ParsedMessage]
  def parse_message(_whdb_row) = raise NotImplementedError

  require_relative "relay/fake_email"
  register(FakeEmail.new.key, FakeEmail)

  require_relative "relay/postmark"
  register(Postmark.new.key, Postmark)

  # @return [Suma::AnonProxy::Relay]
  def self.create!(key)
    return self.registry_create!(key)
  end

  # @return [String]
  def self.active_email_relay_key = Suma::AnonProxy.email_relay
  # @return [Suma::AnonProxy::Relay]
  def self.active_email_relay = self.create!(self.active_email_relay_key)
end
