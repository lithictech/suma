# frozen_string_literal: true

require "suma/message"
require "suma/simple_registry"

class Suma::Message::Carrier
  extend Suma::SimpleRegistry
  include Appydays::Loggable

  def key = raise NotImplementedError

  # Send the message delivery through the carrier and return the message id.
  # Each carrier can have specific arguments for +send!+.
  def send!(*) = raise NotImplementedError

  # Decode a message sent through the +send!+ method.
  def decode_message_id(msg_id) = msg_id

  # Return the link to view the message in the carrier dashboard.
  # Return nil if not supported.
  # Called with the decoded message id.
  def external_link_for(_msg_id) = nil

  # Return true if +fetch_message_details+ is implemented.
  def can_fetch_details? = false

  # Fetch a hash of the message details from the carrier API.
  # Return nil if not supported.
  def fetch_message_details(_msg_id) = nil
end

require_relative "carrier/noop"
Suma::Message::Carrier.register(:noop, Suma::Message::Carrier::Noop)
require_relative "carrier/noop_extended"
Suma::Message::Carrier.register(:noop_extended, Suma::Message::Carrier::NoopExtended)
require_relative "carrier/signalwire"
Suma::Message::Carrier.register(:signalwire, Suma::Message::Carrier::Signalwire)
require_relative "carrier/twilio_verify"
Suma::Message::Carrier.register(:twilio_verify, Suma::Message::Carrier::TwilioVerify)
