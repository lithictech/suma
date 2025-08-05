# frozen_string_literal: true

require "suma/payment/funding_transaction/strategy"
require "suma/payment/payout_transaction/strategy"
require "suma/postgres/model"

class Suma::Payment::OffPlatformStrategy < Suma::Postgres::Model(:payment_off_platform_strategies)
  include Suma::AdminLinked
  include Suma::Payment::FundingTransaction::Strategy
  include Suma::Payment::PayoutTransaction::Strategy

  one_to_one :funding_transaction, class: "Suma::Payment::FundingTransaction"
  one_to_one :payout_transaction, class: "Suma::Payment::PayoutTransaction"
  many_to_one :created_by, class: "Suma::Member"

  def transaction = self.funding_transaction || self.payout_transaction
  def type = self.funding_transaction ? "Funding" : "Payout"

  def short_name = "Off Platform Payment"
  def originating_instrument_label = "Off Platform"
  def check_validity = []

  def admin_details
    return {
      "Transacted At" => self.transacted_at,
      "Created By" => self.created_by&.name,
      "Check/Transaction" => self.check_or_transaction_number,
      "Note" => self.note,
    }
  end

  def ready_to_collect_funds? = true
  def collect_funds = true
  def funds_cleared? = true
  def funds_canceled? = false

  def ready_to_send_funds? = true
  def send_funds = true
  def funds_settled? = true

  def rel_admin_link = "/payment-off-platform/#{self.id}/edit"

  def before_save
    [:note, :check_or_transaction_number].each do |f|
      self[f] = self[f].strip if self[f]
    end
    super
  end
end
