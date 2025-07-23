# frozen_string_literal: true

require "appydays/loggable"
require "suma/twilio"

class Suma::Message::Transport::TwilioVerify < Suma::Message::Transport
  include Appydays::Loggable

  class UnknownVerificationId < StandardError; end

  def initialize(channel)
    super()
    @channel = channel.to_s
    @type = :"otp_#{channel}"
    @smstransport = Suma::Message::Transport::Sms.new
  end

  attr_reader :type

  def carrier = Suma::Message::Carrier.registry_create!(:twilio_verify)
  def supports_layout? = false
  def recipient(to) = @smstransport.recipient(to)
  def allowlisted?(delivery) = @smstransport.allowlisted?(delivery)

  def add_bodies(delivery, content)
    bodies = []
    bodies << delivery.add_body(content:, mediatype: "text/plain")
    return bodies
  end

  def send!(delivery)
    to_phone = Suma::PhoneNumber.format_e164(delivery.to)
    raise Suma::Message::UndeliverableRecipient, "Number '#{to_phone}' not allowlisted" unless
      @smstransport.allowlisted_phone?(to_phone)

    return self.carrier.send!(
      to: to_phone,
      code: delivery.bodies.first.content.strip,
      locale: delivery.template_language,
      channel: @channel,
    )
  end
end
