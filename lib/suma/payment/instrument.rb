# frozen_string_literal: true

module Suma::Payment::Instrument
  def to_display
    raise NotImplementedError
  end

  def payment_method_type
    raise NotImplementedError
  end

  def legal_entity_display
    return Suma::LegalEntity::Display.new(self.legal_entity)
  end

  class Display
    attr_reader :institution_name, :institution_logo, :institution_color, :name, :last4, :address, :admin_label

    def initialize(opts={})
      opts.each { |k, v| self.instance_variable_set("@#{k}", v) }
      @admin_label = "#{self.name}/#{self.last4}"
      @admin_label += " (#{self.institution_name})" unless self.name&.include?(self.institution_name || "")
    end

    def to_h
      return {
        institution_name: self.institution_name,
        institution_logo: self.institution_logo,
        institution_color: self.institution_color,
        name: self.name,
        last4: self.last4,
        address: self.address,
        admin_label: self.admin_label,
      }
    end
  end
end