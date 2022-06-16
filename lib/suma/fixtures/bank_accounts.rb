# frozen_string_literal: true

require "suma/fixtures"
require "suma/bank_account"

module Suma::Fixtures::BankAccounts
  extend Suma::Fixtures

  fixtured_class Suma::BankAccount

  routing_numbers = ["011103093", "067014822", "211274450", "211370545", "054001725", "011400071",
                     "031201360", "026013673", "021302567", "053902197", "036001808", "011600033",]
  base :bank_account do
    self.routing_number ||= routing_numbers.sample(1)
    self.account_number ||= Faker::Bank.account_number
    self.account_type ||= ["checking", "savings"].sample
    self.name ||= "#{self.to_display.institution_name} #{self.account_type.capitalize}"
  end

  before_saving do |instance|
    instance.legal_entity ||= Suma::Fixtures.legal_entity.create
    instance
  end

  decorator :member do |c={}|
    c = Suma::Fixtures.customer(c).create unless c.is_a?(Suma::Member)
    self.legal_entity = c.legal_entity
  end

  decorator :with_legal_entity do |le={}|
    le = Suma::Fixtures.legal_entity(le).create unless le.is_a?(Suma::LegalEntity)
    self.legal_entity = le
  end

  decorator :verified do |at=Time.now|
    self.verified_at = at
  end
end
