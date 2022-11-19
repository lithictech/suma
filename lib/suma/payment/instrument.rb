# frozen_string_literal: true

require "suma/admin_linked"
require "suma/payment"

module Suma::Payment::Instrument
  Institution = Struct.new(:name, :logo, :color, keyword_init: true)

  def payment_method_type
    raise NotImplementedError
  end

  def rel_admin_link
    raise NotImplementedError
  end

  def can_use_for_funding?
    raise NotImplementedError
  end

  # @return [Institution]
  def institution
    raise NotImplementedError
  end

  def admin_label
    lbl = "#{self.name}/#{self.last4}"
    inst_name = self.institution.name
    lbl += " (#{inst_name})" unless self.name&.include?(inst_name || "")
    return lbl
  end

  def simple_label
    raise NotImplementedError
  end

  def search_label
    lbl = "#{self.legal_entity.name}: #{self.name} x-#{self.last4}, #{self.institution.name}"
    return lbl
  end
end
