# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/payment/off_platform_strategy"

module Suma::Fixtures::OffPlatformPaymentStrategies
  extend Suma::Fixtures

  fixtured_class Suma::Payment::OffPlatformStrategy

  base :off_platform_payment_strategy do
    self.note ||= Faker::Lorem.sentence
    self.transacted_at ||= Time.now
  end
end
