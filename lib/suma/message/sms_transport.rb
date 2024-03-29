# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"
require "suma/message/transport"
require "suma/signalwire"
require "suma/twilio"

class Suma::Message::SmsTransport < Suma::Message::Transport
  include Appydays::Configurable
  include Appydays::Loggable

  register_transport(:sms)

  configurable(:sms) do
    setting :allowlist, [], convert: ->(s) { s.split.map { |p| Suma::PhoneNumber.format_e164(p) || p } }
    setting :from, "15554443333"
    # If set, any message deliveries using this template will use Signalwire verify, not normal SMS.
    setting :verification_template, "verification"
    # This is used to extract the verification code from a template.
    # Must be coordinated with with the code generator.
    # Default: match a word of only digits, surrounded by spaces or line start/end.
    setting :verification_code_regex, '\b(\d+)\b'
    # If set, disable SMS (but allow verifications)
    setting :provider_disabled, false
  end

  attr_accessor :allowlist

  def initialize(*)
    super
    @allowlist = self.class.allowlist.freeze
  end

  def type = :sms
  def service = "signalwire"
  def supports_layout? = false

  def recipient(to)
    if to.is_a?(Suma::Member)
      raise Suma::InvalidPrecondition, "Member[#{to.id}] has no phone" if to.phone.blank?
      return Suma::Message::Recipient.new(to.phone, to)
    end
    return Suma::Message::Recipient.new(to, nil)
  end

  def allowlisted?(delivery)
    return self.allowlisted_phone?(Suma::PhoneNumber.format_e164(delivery.to))
  end

  def allowlisted_phone?(phone)
    return false if phone.nil?
    phone = phone.delete_prefix("+")
    allowed = self.allowlist.map { |s| s.delete_prefix("+") }
    return allowed.any? { |pattern| File.fnmatch(pattern, phone) }
  end

  def send!(delivery)
    to_phone = Suma::PhoneNumber.format_e164(delivery.to)
    raise Suma::Message::Transport::Error, "Could not format phone number" if
      to_phone.nil?

    (from_phone = Suma::PhoneNumber.format_e164(self.class.from)) or
      raise Suma::InvalidPrecondition, "SMS_TRANSPORT_FROM is invalid"

    raise Suma::Message::Transport::UndeliverableRecipient, "Number '#{to_phone}' not allowlisted" unless
      self.allowlisted_phone?(to_phone)

    body = delivery.bodies.first.content
    if delivery.template == self.class.verification_template
      self.logger.info("send_verification_sms", to: to_phone)
      rmatch = Regexp.new(self.class.verification_code_regex).match(body.strip)
      raise "Cannot extract verification code from '#{body}' using '#{self.class.verification_code_regex}'" if
        rmatch.nil?
      begin
        response = Suma::Twilio.send_verification(to_phone, code: rmatch[1], locale: delivery.template_language)
      rescue Twilio::REST::RestError => e
        if (logmsg = FATAL_TWILIO_ERROR_CODES[e.code])
          self.logger.warn(logmsg, phone: to_phone, body:, error: e.response.body)
          raise Suma::Message::Transport::UndeliverableRecipient, "Fatal Twilio error: #{logmsg}"
        end
        raise(e)
      end
      # If we send the reset code multiple times with multiple deliveries,
      # we get the same SID/message id, but different attempts. Disambiguate them,
      # since we expect message ids to be empty.
      sid = "#{response.sid}-#{response.send_code_attempts.length}"
    elsif self.class.provider_disabled
      self.logger.warn("sms_provider_disabled", phone: to_phone, body:)
      raise Suma::Message::Transport::UndeliverableRecipient, "SMS provider disabled"
    else
      self.logger.info("send_twilio_sms", to: to_phone, message_preview: body.slice(0, 20))
      begin
        response = Suma::Signalwire.send_sms(from_phone, to_phone, body)
      rescue Twilio::REST::RestError => e
        if (logmsg = FATAL_SIGNALWIRE_ERROR_CODES[e.code])
          self.logger.warn(logmsg, phone: to_phone, body:, error: e.response.body)
          raise Suma::Message::Transport::UndeliverableRecipient, "Fatal Signalwire error: #{logmsg}"
        end
        raise(e)
      end
      sid = response.sid
    end
    self.logger.debug { "Response from Signalwire: %p" % [response] }
    return sid
  end

  # Signalwire errors will usually be re-raised, but in some cases, we want to handle them by not handling them,
  # like for invalid phone numbers which there's no point worrying about.
  # So we just log and delete the delivery.
  FATAL_SIGNALWIRE_ERROR_CODES = {
    "21217" => "signalwire_invalid_phone_number",
  }.freeze

  FATAL_TWILIO_ERROR_CODES = {
    60_200 => "twilio_invalid_phone_number",
  }.freeze

  def add_bodies(delivery, content)
    bodies = []
    raise "content is not set" if content.blank?
    bodies << delivery.add_body(content:, mediatype: "text/plain")
    return bodies
  end
end
