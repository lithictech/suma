# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::MarketingSmsCampaigns
  extend Suma::Fixtures

  fixtured_class Suma::Marketing::SmsCampaign

  base :marketing_sms_campaign do
    self.name ||= Faker::Lorem.words
  end

  before_saving do |instance|
    instance.body ||= Suma::Fixtures.translated_text.create
    instance
  end

  decorator :with_body do |en, es=nil|
    self.body = Suma::Fixtures.translated_text(en:, es:).create
  end
end
