# frozen_string_literal: true

require "suma/payment/funding_transaction/strategy"
require "suma/payment/payout_transaction/strategy"
require "suma/postgres/model"

class Suma::Payment::OffPlatformStrategy < Suma::Postgres::Model(:payment_off_platform_strategies)
  include Suma::Payment::FundingTransaction::Strategy
  include Suma::Payment::PayoutTransaction::Strategy

  one_to_one :funding_transaction, class: "Suma::Payment::FundingTransaction"
  one_to_one :payout_transaction, class: "Suma::Payment::PayoutTransaction"
  many_to_one :created_by, class: "Suma::Member"

  def originating_instrument = nil
  def short_name = "Off Platform Payment"
  def check_validity = []

  def ready_to_collect_funds? = true
  def collect_funds = true
  def funds_cleared? = true
  def funds_canceled? = false

  def ready_to_send_funds? = true
  def send_funds = true
  def funds_settled? = true

  def before_save
    [:note, :check_or_transaction_number].each do |f|
      self[f] = self[f].strip if self[f]
    end
    super
  end
end
