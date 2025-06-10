# frozen_string_literal: true

require "suma/message"
require "suma/simple_registry"

class Suma::Message::Transport
  extend Suma::SimpleRegistry

  # Override this if a transport needs a different 'to' than the email,
  # like for text messages.
  def recipient(to)
    if to.is_a?(Suma::Member)
      (email = to.email) or raise "Member #{to.id} has no default email"
      return Suma::Message::Recipient.new(email, to)
    end
    return Suma::Message::Recipient.new(to, nil)
  end

  # Calls the 3rd party with message/content and returns its transport ID.
  def send!(_delivery) = raise NotImplementedError

  # Returns true if message can be delivered.
  def allowlisted?(_delivery) = raise NotImplementedError
end

require_relative "email_transport"
Suma::Message::Transport.register(:email, Suma::Message::EmailTransport)
require_relative "fake_transport"
Suma::Message::Transport.register(:fake, Suma::Message::FakeTransport)
require_relative "sms_transport"
Suma::Message::Transport.register(:sms, Suma::Message::SmsTransport)
