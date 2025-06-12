# frozen_string_literal: true

require "suma/message"
require "suma/simple_registry"

class Suma::Message::Transport
  extend Suma::SimpleRegistry

  class SendResult < Suma::TypedStruct
    attr_reader :message_id, :service
  end

  # The service type, like :sms or :email.
  # @return [Symbol]
  def type = raise NotImplementedError
  # The external service, like "signalwire" or "postmark".
  def service = raise NotImplementedError
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
end

require_relative "email_transport"
Suma::Message::Transport.register(:email, Suma::Message::EmailTransport)
require_relative "fake_transport"
Suma::Message::Transport.register(:fake, Suma::Message::FakeTransport)
require_relative "otp_sms_transport"
Suma::Message::Transport.register(:otp_sms, Suma::Message::OtpSmsTransport)
require_relative "sms_transport"
Suma::Message::Transport.register(:sms, Suma::Message::SmsTransport)
