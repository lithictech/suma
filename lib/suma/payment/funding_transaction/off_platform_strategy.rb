# frozen_string_literal: true

require "suma/stripe"
require "suma/payment/funding_transaction/strategy"
require "suma/postgres/model"

class Suma::Payment::FundingTransaction::OffPlatformStrategy <
  Suma::Postgres::Model(:payment_funding_transaction_off_platform_strategies)
  include Suma::Payment::FundingTransaction::Strategy

  one_to_one :funding_transaction, class: "Suma::Payment::FundingTransaction"
  many_to_one :created_by, class: "Suma::Member"

  def originating_instrument = nil
  def short_name = "Off Platform Funding"
  def check_validity = []
  def ready_to_collect_funds? = true
  def collect_funds = true
  def funds_cleared? = true
  def funds_canceled? = false

  def before_create
    self.created_by_name = self.created_by.name
    super
  end
end
