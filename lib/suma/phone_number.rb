# frozen_string_literal: true

module Suma::PhoneNumber
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

    def self.format(s)
      raise ArgumentError, "#{s} must be a normalized to #{REGEXP}" unless self.valid_normalized?(s)
      return "(#{s[1..3]}) #{s[4..6]}-#{s[7..]}"
    end
  end

  def self.faked_unreachable_phone
    # +37 is a discontinued code for East Germany, and we just fill in the rest with random chars.
    return "37" + rand(1e12...1e13).to_i.to_s
  end
end
