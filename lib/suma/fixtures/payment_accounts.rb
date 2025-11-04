# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/payment/account"

module Suma::Fixtures::PaymentAccounts
  extend Suma::Fixtures

  fixtured_class Suma::Payment::Account

  base :payment_account do
  end

  before_saving do |instance|
    if instance.member_id.nil? && instance.vendor_id.nil? && !instance.is_platform_account
      instance.member = Suma::Fixtures.member.create
    end
    instance
  end

  decorator :platform do |is=true|
    self.is_platform_account = is
  end
end
