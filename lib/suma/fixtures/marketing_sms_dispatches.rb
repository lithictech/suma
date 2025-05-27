# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::MarketingSmsDispatches
  extend Suma::Fixtures

  fixtured_class Suma::Marketing::SmsDispatch

  base :marketing_sms_dispatch do
  end

  before_saving do |instance|
    instance.sms_broadcast ||= Suma::Fixtures.marketing_sms_broadcast.create
    instance.member ||= Suma::Fixtures.member.create
    instance
  end

  decorator :sent do |msgid=SecureRandom.hex(2), at: Time.now|
    self.sent_at = at
    self.transport_message_id = msgid
  end

  decorator :to do |opts={}|
    opts = Suma::Fixtures.member(**opts).create unless opts.is_a?(Suma::Member)
    self.member = opts
  end

  decorator :canceled do |at: Time.now|
    self.cancel(at:)
  end
end
