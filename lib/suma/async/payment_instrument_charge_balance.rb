# frozen_string_literal: true

require "amigo/job"

# When a payment instrument is created or updated,
# charge any outstanding negative balance. This should be safe,
# since members should never carry around a negative balance.
class Suma::Async::PaymentInstrumentChargeBalance
  extend Amigo::Job

  on(/^suma\.payment\.[a-z]+\.(created|updated)$/)

  def _perform(event)
    cls = Suma::Postgres::ModelPubsub.model_for_event_topic(event.name)
    pi = self.lookup_model(cls, event)
    return unless pi.is_a?(Suma::Payment::Instrument::Interface)
    return if pi.soft_deleted?
    return unless pi.usable_for_funding?
    balance = pi.member.payment_account!.cash_ledger!.balance
    return unless balance.negative?
    Suma::Payment::FundingTransaction.start_and_transfer(
      pi.member,
      amount: -balance,
      instrument: pi,
      apply_at: Time.now,
    )
  end
end
