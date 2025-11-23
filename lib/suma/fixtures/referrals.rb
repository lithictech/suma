# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::Referrals
  extend Suma::Fixtures

  fixtured_class Suma::Member::Referral

  base :referral do
    self.source ||= Faker::Lorem.word
    self.campaign ||= ["", Faker::Lorem.word].sample
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    instance
  end
end
