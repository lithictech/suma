# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/customer"

module Suma::Fixtures::Journeys
  extend Suma::Fixtures

  fixtured_class Suma::Customer::Journey

  base :journey do
    self.name ||= Faker::NatoPhoneticAlphabet.code_word
    self.message ||= "Fixtured journey"
    self.subject_type ||= "Fixtured"
    self.subject_id ||= Time.now.to_i
  end

  before_saving do |instance|
    instance.customer ||= Suma::Fixtures.customer.create
    instance
  end
end
