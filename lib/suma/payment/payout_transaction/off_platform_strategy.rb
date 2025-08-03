# frozen_string_literal: true

require "suma/stripe"
require "suma/payment/payout_transaction/strategy"
require "suma/postgres/model"

class Suma::Payment::PayoutTransaction::OffPlatformStrategy <
  Suma::Postgres::Model(:payment_payout_transaction_off_platform_strategies)
  include Suma::Payment::PayoutTransaction::Strategy

  one_to_one :payout_transaction, class: "Suma::Payment::PayoutTransaction"
  many_to_one :created_by, class: "Suma::Member"

  def short_name = "Off Platform Payout"
  def check_validity = []
  def ready_to_send_funds? = true
  def send_funds = true
  def funds_settled? = true

  def before_create
    self.created_by_name = self.created_by.name
    super
  end
end
