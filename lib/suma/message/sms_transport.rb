# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"
require "suma/message/transport"
require "suma/twilio"

class Suma::Message::SmsTransport < Suma::Message::Transport
  include Appydays::Configurable
  include Appydays::Loggable

  register_transport(:sms)

  configurable(:sms) do
    setting :allowlist, [], convert: ->(s) { s.split.map { |p| Suma::Twilio.format_phone(p) || p } }
    setting :from, "15554443333"
  end

  attr_accessor :allowlist

  def initialize(*)
    super
    @allowlist = self.class.allowlist.freeze
  end

  def type
    return :sms
  end

  def service
    return "twilio"
  end

  def supports_layout?
    false
  end

  def recipient(to)
    if to.is_a?(Suma::Member)
      raise Suma::InvalidPrecondition, "Member[#{to.id}] has no phone" if to.phone.blank?
      return Suma::Message::Recipient.new(to.phone, to)
    end
    return Suma::Message::Recipient.new(to, nil)
  end

  def allowlisted?(delivery)
    return self._allowlisted?(Suma::Twilio.format_phone(delivery.to))
  end

  def _allowlisted?(phone)
    return false if phone.nil?
    phone = phone.delete_prefix("+")
    allowed = self.allowlist.map { |s| s.delete_prefix("+") }
    return allowed.any? { |pattern| File.fnmatch(pattern, phone) }
  end

  def send!(delivery)
    # The number provided to Twilio must be a phone number in E.164 format.
    formatted_phone = Suma::Twilio.format_phone(delivery.to)
    raise Suma::Message::Transport::Error, "Could not format phone number" if
      formatted_phone.nil?

    raise Suma::Message::Transport::UndeliverableRecipient, "Number '#{formatted_phone}' not allowlisted" unless
      self._allowlisted?(formatted_phone)

    body = delivery.bodies.first.content
    self.logger.info("send_twilio_sms", to: formatted_phone, message_preview: body.slice(0, 20))
    begin
      response = Suma::Twilio.send_sms(self.class.from, formatted_phone, body)
    rescue Twilio::REST::RestError => e
      if (logmsg = FATAL_TWILIO_ERRORS[e.code])
        self.logger.warn(logmsg, phone: formatted_phone, body:, error: e.response.body)
        raise Suma::Message::Transport::UndeliverableRecipient, "Fatal Twilio error: #{logmsg}"
      end
      raise(e)
    end
    self.logger.debug { "Response from Twilio: %p" % [response] }
    return response.sid
  end

  # Twilio errors will usually be re-raised, but in some cases, we want to handle them by not handling them,
  # like for invalid phone numbers which there's no point worrying about.
  # So we just log and delete the delivery.
  FATAL_TWILIO_ERRORS = {
    21_211 => "twilio_invalid_phone_number",
    21_408 => "twilio_unsupported_region",
    21_610 => "twilio_blacklist_rule",
  }.freeze

  def add_bodies(delivery, content)
    bodies = []
    raise "content is not set" if content.blank?
    bodies << delivery.add_body(content:, mediatype: "text/plain")
    return bodies
  end
end
