# frozen_string_literal: true

require "suma/vendor"

# Mixin for objects that have vendor service categories.
module Suma::Vendor::HasServiceCategories
  # @!attribute vendor_service_categories
  # @return [Array<Suma::Vendor::ServiceCategory>]

  def self.included(mod)
    return if mod.instance_methods.include?(:vendor_service_categories)
    raise TypeError, "#{mod} must define a vendor_service_categories method or association"
  end
end
