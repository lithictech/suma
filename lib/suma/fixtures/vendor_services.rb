# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/vendor/service"

module Suma::Fixtures::VendorServices
  extend Suma::Fixtures

  fixtured_class Suma::Vendor::Service

  base :vendor_service do
    self.internal_name ||= Faker::Commerce.product_name
    self.external_name ||= self.internal_name.downcase
    self.period ||= Faker::Suma.number(50..2).days.ago..Faker::Suma.number(2..50).days.from_now
  end

  before_saving do |instance|
    instance.vendor ||= Suma::Fixtures.vendor.create
    instance
  end

  decorator :mobility, presave: true do
    self.add_category(Suma::Fixtures.vendor_service_category.mobility.create)
    self.mobility_vendor_adapter_key = "fake" if self.mobility_vendor_adapter_key.blank?
  end

  decorator :food, presave: true do
    self.add_category(Suma::Fixtures.vendor_service_category.food.create)
  end

  decorator :with_categories, presave: true do |*cats|
    cats << {} if cats.empty?
    cats.each do |c|
      c = Suma::Fixtures.vendor_service_category.create(c) unless c.is_a?(Suma::Vendor::ServiceCategory)
      self.add_category(c)
    end
  end

  decorator :with_constraints, presave: true do |*constraints|
    constraints.each { |c| self.add_eligibility_constraint(c) }
  end
end
