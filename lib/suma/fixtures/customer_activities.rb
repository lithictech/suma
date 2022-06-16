# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/customer"

module Suma::Fixtures::CustomerActivities
  extend Suma::Fixtures

  fixtured_class Suma::Member::Activity

  base :member_activity do
    self.message_name ||= Faker::NatoPhoneticAlphabet.code_word
    self.summary ||= "Fixtured activity"
    self.subject_type ||= "Fixtured"
    self.subject_id ||= Time.now.to_i
  end

  before_saving do |instance|
    instance.customer ||= Suma::Fixtures.customer.create
    instance
  end
end
