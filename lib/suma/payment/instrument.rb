# frozen_string_literal: true

require "mimemagic"

require "suma/admin_linked"
require "suma/payment"

module Suma::Payment::Instrument
  class Institution
    attr_reader :name, :logo_src, :color

    def initialize(name:, logo:, color:)
      @name = name
      @color = color
      @logo_src = Suma::Payment::Instrument.logo_to_src(logo)
    end
  end

  PNG_PREFIX = "iVBORw0KGgo"

  def self.logo_to_src(arg)
    return "" if arg.nil?
    return arg if /^[a-z]{2,10}:/.match?(arg)
    return "data:image/png;base64,#{arg}" if arg.start_with?(PNG_PREFIX)
    begin
      raw = Base64.strict_decode64(arg[...(4 * 10)]) # base64 string length is divisible by 4
    rescue ArgumentError
      return arg
    end
    matched = MimeMagic.by_magic(raw)
    return arg unless matched
    return "data:#{matched};base64,#{arg}"
  end

  def payment_method_type = raise NotImplementedError
  def rel_admin_link = raise NotImplementedError
  def can_use_for_funding? = raise NotImplementedError
  # @return [Institution]
  def institution = raise NotImplementedError

  def admin_label
    lbl = "#{self.name}/#{self.last4}"
    inst_name = self.institution.name
    lbl += " (#{inst_name})" unless self.name&.include?(inst_name || "")
    return lbl
  end

  def simple_label = raise NotImplementedError

  def search_label
    lbl = "#{self.legal_entity.name}: #{self.name} x-#{self.last4}, #{self.institution.name}"
    return lbl
  end
end
