# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/payment/ledger"

module Suma::Fixtures::Ledgers
  extend Suma::Fixtures

  fixtured_class Suma::Payment::Ledger

  base :ledger do
    self.currency ||= "USD"
  end

  before_saving do |instance|
    instance.account ||= Suma::Fixtures.payment_account.create
    instance.name ||= Faker::Lorem.word
    instance
  end

  decorator :with_categories, presave: true do |*cats|
    cats.each { |c| self.add_vendor_service_category(c) }
  end

  decorator :member do |c={}|
    c = Suma::Fixtures.member(c).create unless c.is_a?(Suma::Member)
    c.payment_account ||= Suma::Fixtures.payment_account.create(member: c)
    self.account = c.payment_account
  end

  decorator :category, presave: true do |name|
    raise ArgumentError, "#{name} must be a Symbol (the fixture decorator method)" unless name.is_a?(Symbol)
    self.add_vendor_service_category(Suma::Fixtures.vendor_service_category.send(name).create)
    self.name ||= name
  end
end
