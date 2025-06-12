# frozen_string_literal: true

class Suma::Message::FakeTransport < Suma::Message::Transport
  extend Suma::MethodUtilities

  singleton_attr_reader :sent_deliveries
  @sent_deliveries = []

  singleton_attr_accessor :allowlisted_callback
  @allowlisted_callback = nil

  singleton_attr_accessor :send_callback
  @send_callback = nil

  def self.reset!
    self.sent_deliveries.clear
    self.allowlisted_callback = nil
    self.send_callback = nil
  end

  def type = :fake
  def service = "fake"
  def supports_layout? = true

  def recipient(to) = Suma::Message::EmailTransport.new.recipient(to)

  def add_bodies(delivery, content)
    bodies = []
    bodies << delivery.add_body(content: content.to_s, mediatype: "text/plain")
    return bodies
  end

  def allowlisted?(delivery)
    denied = Suma::Message::FakeTransport.allowlisted_callback&.call(delivery)
    return !denied
  end

  def send!(delivery)
    Suma.logger.debug "Storing Delivery[%d] to %s as sent" % [delivery.id, delivery.to]
    Suma::Message::FakeTransport.sent_deliveries << delivery
    return Suma::Message::FakeTransport.send_callback.call(delivery) if Suma::Message::FakeTransport.send_callback
    return "#{delivery.id}-#{SecureRandom.hex(6)}"
  end
end
