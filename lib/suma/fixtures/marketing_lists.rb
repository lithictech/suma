# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::MarketingLists
  extend Suma::Fixtures

  fixtured_class Suma::Marketing::List

  base :marketing_list do
    self.name ||= Faker::Lorem.words
  end

  before_saving do |instance|
    instance
  end

  decorator :members, presave: true do |*members|
    members.each do |m|
      self.add_member(m)
    end
  end
end
