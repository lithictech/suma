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
    instance.customer ||= Suma::Fixtures.customer.create
    instance
  end
end
