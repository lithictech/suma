# frozen_string_literal: true

require "suma/message"
require "suma/simple_registry"

class Suma::Message::Transport
  extend Suma::SimpleRegistry
  include Appydays::Loggable

  class SendResult < Suma::TypedStruct
    attr_reader :message_id, :service
  end

  # The service type, like :sms or :email.
  # @return [Symbol]
  def type = raise NotImplementedError
  # Return true if the transport supports layouts.
  # Usually true for email/designed formats, and false for simpler transports like sms.
  def supports_layout? = raise NotImplementedError
  # Return the +Suma::Message::Recipient+ for the member or phone/email.
  def recipient(to) = raise NotImplementedError
  # Returns true if message can be delivered.
  def allowlisted?(_delivery) = raise NotImplementedError
  # Add +Suma::Message::Body+ instances to the given delivery.
  def add_bodies(_delivery, _rendered_template_contents) = raise NotImplementedError
  # Calls the 3rd party transport service with the delivery's message/content.
  # @return [SendResult]
  def send!(_delivery) = raise NotImplementedError
  # The current carrier for this transport.
  # Some transports may use a single carrier, or carriers can be configured, etc.
  # @return [Suma::Message::Carrier]
  def carrier = raise NotImplementedError
end

require_relative "transport/email"
Suma::Message::Transport.register(:email, Suma::Message::Transport::Email)
require_relative "transport/fake"
Suma::Message::Transport.register(:fake, Suma::Message::Transport::Fake)
require_relative "transport/otp_sms"
Suma::Message::Transport.register(:otp_sms, Suma::Message::Transport::OtpSms)
require_relative "transport/sms"
Suma::Message::Transport.register(:sms, Suma::Message::Transport::Sms)
