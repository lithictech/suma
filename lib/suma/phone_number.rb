# frozen_string_literal: true

module Suma::PhoneNumber
  class BadFormat < StandardError; end

  class US
    REGEXP = /^1[0-9]{10}$/

    def self.normalize(s)
      norm = Phony.normalize(s, cc: "1")
      norm = "1#{norm}" if norm.length == 10 && norm.first == "1"
      return norm
    end

    def self.valid?(s)
      return false if s.nil?
      return self.valid_normalized?(self.normalize(s))
    end

    def self.valid_normalized?(s)
      return REGEXP.match?(s)
    end

    # Given a valid, normalized phone number, format it as (xxx) xxx-xxxx.
    # Return nil if the phone number is invalid.
    def self.format?(s)
      return nil unless self.valid_normalized?(s)
      return "(#{s[1..3]}) #{s[4..6]}-#{s[7..]}"
    end

    # See +format?+, but raise if the given phone number is invalid.
    def self.format(s)
      self.format?(s) or raise BadFormat, "#{s} must be a normalized to #{REGEXP}"
    end
  end

  def self.faked_unreachable_phone
    # +37 is a discontinued code for East Germany, and we just fill in the rest with random chars.
    return "37" + rand(1e12...1e13).to_i.to_s
  end

  # Given a string representing a phone number, returns that phone number in E.164 format (+1XXX5550100).
  # Assumes all provided phone numbers are US numbers.
  # Does not check for invalid area codes.
  def self.format_e164?(phone)
    return nil if phone.blank?
    return phone if /^\+1\d{10}$/.match?(phone)
    phone = phone.gsub(/\D/, "")
    return "+1" + phone if phone.size == 10
    return "+" + phone if phone.size == 11
  end

  # Same as +format_e164?+, but raise if the given number is invalid.
  def self.format_e164(phone)
    self.format_e164?(phone) or raise BadFormat, "Could not format #{phone} as e164"
  end

  # Given a phone number in E164 format (+<numbers>),
  # remove the leading 'plus' sign. Providers may use a leading plus,
  # but we don't in our database, so this can be used to convert.
  # Return nil if the given number is not in E164 format.
  def self.unformat_e164?(e164)
    return nil unless /^\+\d+$/.match?(e164)
    return e164[1..]
  end

  def self.unformat_e164(e164)
    self.unformat_e164?(e164) or raise BadFormat, "#{e164} must be in E164 format"
  end

  def self.format_display(s)
    if (us = US.format?(s))
      return us
    end
    return s
  end
end
