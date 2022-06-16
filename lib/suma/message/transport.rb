# frozen_string_literal: true

require "suma/message"

class Suma::Message::Transport
  extend Suma::MethodUtilities

  class Error < RuntimeError; end
  class UndeliverableRecipient < Error; end

  singleton_attr_reader :transports
  @transports = {}

  singleton_attr_accessor :override

  def self.register_transport(type)
    Suma::Message::Transport.transports[type] = self
  end

  def self.for(type)
    type = Suma::Message::Transport.override || type
    return Suma::Message::Transport.transports[type.to_sym]&.new
  end

  def self.for!(type)
    (t = self.for(type)) or raise Suma::Message::InvalidTransportError, "invalid transport: %p" % type
    return t
  end

  # Override this if a transport needs a different 'to' than the email,
  # like for text messages.
  def recipient(to)
    if to.is_a?(Suma::Member)
      (email = to.email) or raise "Customer #{to.id} has no default email"
      return Suma::Message::Recipient.new(email, to)
    end
    return Suma::Message::Recipient.new(to, nil)
  end

  def send!(_delivery)
    raise "Must implement in subclass. Call 3rd party with message/content and return transport ID."
  end

  def allowlisted?(_delivery)
    raise "Must be implemented in subclass. Return true if message can be delivered."
  end
end
