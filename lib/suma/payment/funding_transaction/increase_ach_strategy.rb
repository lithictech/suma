# frozen_string_literal: true

require "suma/increase"
require "suma/payment/funding_transaction/strategy"
require "suma/postgres/model"

class Suma::Payment::FundingTransaction::IncreaseAchStrategy <
  Suma::Postgres::Model(:payment_funding_transaction_increase_ach_strategies)
  include Suma::Payment::FundingTransaction::Strategy

  one_to_one :funding_transaction, class: "Suma::Payment::FundingTransaction"
  many_to_one :originating_bank_account, class: "Suma::BankAccount"

  def short_name
    return "Increase ACH Funding"
  end

  def check_validity
    ba = self.originating_bank_account
    result = []
    (result << "is soft deleted and cannot be used for funding") if ba.soft_deleted?
    (result << "is not verified and cannot be used for funding") unless ba.verified?
    return result
  end

  def ready_to_collect_funds?
    return true
  end

  def collect_funds
    return false if self.ach_transfer_id.present?
    self.ach_transfer_json = Suma::Increase.create_ach_debit_from_bank_account(
      self.originating_bank_account,
      amount_cents: self.funding_transaction.amount.cents,
      memo: self.funding_transaction.memo,
    )
    if self.ach_transfer_id.blank?
      msg = "Increase ACH Transfer Id was not set after API call from #{self.class.name}[#{self.id}]. " \
            "JSON: #{self.ach_transfer_json}"
      raise Suma::InvalidPostcondition, msg
    end
    return true
  end

  def funds_cleared?
    # See https://github.com/lithictech/suma/issues/79
    return false
  end

  def ach_transfer_id
    return self.ach_transfer_json["id"]
  end

  def _external_links_self
    return [] unless self.ach_transfer_id
    return [
      self._external_link(
        "ACH Transfer into Increase Account",
        "#{Suma::Increase.app_url}#{self.ach_transfer_json['path']}",
      ),
      self._external_link(
        "Transaction for ACH Transfer",
        "#{Suma::Increase.app_url}/transactions/#{self.ach_transfer_json['transaction_id']}",
      ),
    ]
  end

  def _external_link_deps
    return [self.originating_bank_account]
  end
end
