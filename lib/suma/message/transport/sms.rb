# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"

class Suma::Message::Transport::Sms < Suma::Message::Transport
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:sms) do
    setting :allowlist, [], convert: ->(s) { s.split.map { |p| Suma::PhoneNumber.format_e164?(p) || p } }
    # If set, disable SMS (but allow verifications).
    setting :provider_disabled, false
  end

  class << self
    def allowlisted_phone?(phone, allowlist: self.allowlist)
      return false if phone.nil?
      phone = phone.delete_prefix("+")
      allowed = allowlist.map { |s| s.delete_prefix("+") }
      return allowed.any? { |pattern| File.fnmatch(pattern, phone) }
    end
  end

  attr_accessor :allowlist

  def initialize
    super
    @allowlist = self.class.allowlist.freeze
  end

  def type = :sms
  def carrier = Suma::Message::Carrier.registry_create!(:signalwire)
  def supports_layout? = false

  def recipient(to)
    if to.is_a?(Suma::Member)
      raise Suma::InvalidPrecondition, "Member[#{to.id}] has no phone" if to.phone.blank?
      str_to = to.phone
      member = to
    else
      str_to = to
      member = nil
    end
    return Suma::Message::Recipient.new(str_to, member, Suma::PhoneNumber::US.format?(str_to))
  end

  def allowlisted?(delivery)
    return self.allowlisted_phone?(Suma::PhoneNumber.format_e164?(delivery.to))
  end

  def allowlisted_phone?(phone) = self.class.allowlisted_phone?(phone, allowlist: self.allowlist)

  def send!(delivery)
    to_phone = Suma::PhoneNumber.format_e164(delivery.to)
    raise Suma::Message::UndeliverableRecipient, "Number '#{to_phone}' not allowlisted" unless
      self.allowlisted_phone?(to_phone)
    override_from = delivery.extra_fields.fetch("from", nil)

    if self.class.provider_disabled
      self.logger.warn("sms_provider_disabled")
      raise Suma::Message::UndeliverableRecipient, "SMS provider disabled"
    end
    return self.carrier.send!(
      override_from:,
      to: to_phone,
      body: delivery.bodies.first.content,
    )
  end

  def add_bodies(delivery, content)
    bodies = []
    bodies << delivery.add_body(content:, mediatype: "text/plain")
    return bodies
  end
end
