# frozen_string_literal: true

class Suma::Message::Transport::Fake < Suma::Message::Transport
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
  def carrier = Suma::Message::Carrier.registry_create!(:noop)
  def supports_layout? = true

  def recipient(to) = Suma::Message::Transport::Email.new.recipient(to)

  def add_bodies(delivery, content)
    bodies = []
    bodies << delivery.add_body(content: content.to_s, mediatype: "text/plain")
    return bodies
  end

  def allowlisted?(delivery)
    denied = self.class.allowlisted_callback&.call(delivery)
    return !denied
  end

  def send!(delivery)
    self.logger.debug "recording_delivery_sent"
    self.class.sent_deliveries << delivery
    return self.class.send_callback.call(delivery) if self.class.send_callback
    return self.carrier.send!(delivery_id: delivery.id)
  end
end
