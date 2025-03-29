# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"
require "suma/message/transport"
require "suma/signalwire"
require "suma/twilio"

class Suma::Message::SmsTransport < Suma::Message::Transport
  include Appydays::Configurable
  include Appydays::Loggable

  class UnknownVerificationId < StandardError; end

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

  class << self
    # Return true if the delivery uses the verification template.
    # @param d [Suma::Message::Delivery]
    def verification_delivery?(d) = d.template == self.verification_template

    # Given the response from the verification service (like a Twilio response),
    # return a suitable string for the delivery's +transport_message_id+ column.
    # The value returned from this must be parseable back into a verification service ID
    # in +transport_message_id_to_verification_id+.
    # @return [String]
    def verification_transport_message_id(sid, sid_disambiguator)
      vtmid = "TV-#{sid}-#{sid_disambiguator}"
      return vtmid
    end

    # Given a +transport_message_id+, return an ID that can be used for the verification service.
    # If the ID cannot be verified, raise an error.
    # @param tmid [String]
    # @return [String]
    def transport_message_id_to_verification_id(tmid)
      if tmid.starts_with?("TV-")
        part = tmid[3..]
        idpart = part.rpartition("-")[0]
        return idpart
      end
      raise UnknownVerificationId, "Could not figure out how to parse a verification id from #{tmid}"
    end
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

    from_phone = delivery.extra_fields.fetch("from", self.class.from)
    (from_phone = Suma::PhoneNumber.format_e164(from_phone)) or
      raise Suma::InvalidPrecondition, "SMS_TRANSPORT_FROM is invalid"

    raise Suma::Message::Transport::UndeliverableRecipient, "Number '#{to_phone}' not allowlisted" unless
      self.allowlisted_phone?(to_phone)

    body = delivery.bodies.first.content
    if self.class.verification_delivery?(delivery)
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
      sid = self.class.verification_transport_message_id(response.sid, response.send_code_attempts.length.to_s)
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
