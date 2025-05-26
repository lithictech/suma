# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::MarketingSmsDispatches
  extend Suma::Fixtures

  fixtured_class Suma::Marketing::SmsDispatch

  base :marketing_sms_dispatch do
  end

  before_saving do |instance|
    instance.sms_campaign ||= Suma::Fixtures.marketing_sms_campaign.create
    instance.member ||= Suma::Fixtures.member.create
    instance
  end

  decorator :sent do |at=Time.now|
    self.sent_at = at
  end
end
