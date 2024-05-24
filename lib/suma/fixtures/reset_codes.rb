# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/member/reset_code"

module Suma::Fixtures::ResetCodes
  extend Suma::Fixtures

  fixtured_class Suma::Member::ResetCode

  base :reset_code do
    self.transport ||= ["sms", "email"].sample
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    instance
  end

  decorator :sms do
    self.transport = "sms"
  end

  decorator :email do
    self.transport = "email"
  end

  decorator :expired do
    self.expire_at = Faker::Number.between(from: 1, to: 100).minutes.ago
  end

  decorator :used do
    self.used = true
  end
end
