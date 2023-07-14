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
    # If set, any message deliveries using this template will use Twilio verify, not normal SMS.
    setting :verification_template, "verification"
    # This is used to extract the verification code from a template.
    # Must be coordinated with with the code generator.
    # Default: match a word of only digits, surrounded by spaces or line start/end.
    setting :verification_code_regex, '\b(\d+)\b'
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
    return self.allowlisted_phone?(Suma::Twilio.format_phone(delivery.to))
  end

  def allowlisted_phone?(phone)
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
      self.allowlisted_phone?(formatted_phone)

    body = delivery.bodies.first.content
    begin
      if delivery.template == self.class.verification_template
        self.logger.info("send_verification_sms", to: formatted_phone)
        rmatch = Regexp.new(self.class.verification_code_regex).match(body.strip)
        raise "Cannot extract verification code from '#{body}' using '#{self.class.verification_code_regex}'" if
          rmatch.nil?
        response = Suma::Twilio.send_verification(formatted_phone, code: rmatch[1], locale: delivery.template_language)
        # If we send the reset code multiple times with multiple deliveries,
        # we get the same SID/message id, but different attempts. Disambiguate them,
        # since we expect message ids to be empty.
        sid = "#{response.sid}-#{response.send_code_attempts.length}"
      else
        self.logger.info("send_twilio_sms", to: formatted_phone, message_preview: body.slice(0, 20))
        response = Suma::Twilio.send_sms(self.class.from, formatted_phone, body)
        sid = response.sid
      end
    rescue Twilio::REST::RestError => e
      if (logmsg = FATAL_TWILIO_ERRORS[e.code])
        self.logger.warn(logmsg, phone: formatted_phone, body:, error: e.response.body)
        raise Suma::Message::Transport::UndeliverableRecipient, "Fatal Twilio error: #{logmsg}"
      end
      raise(e)
    end
    self.logger.debug { "Response from Twilio: %p" % [response] }
    return sid
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
