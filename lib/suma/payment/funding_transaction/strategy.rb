# frozen_string_literal: true

require "suma/external_links"
require "suma/payment/funding_transaction"
require "suma/payment/strategy_helpers"

module Suma::Payment::FundingTransaction::Strategy
  include Suma::ExternalLinks
  include Suma::Payment::StrategyHelpers

  # Return a string that summarizes the strategy.
  # Use whatever is most useful for an admin to see,
  # it does not have to be totally unambiguous.
  # @return [String]
  def short_name = raise NotImplementedError

  # Return an array of reasons this strategy is not valid
  # to be created. Usually this is something like an instrument
  # being soft deleted or not being registered in an external service;
  # these issues are terminal, so need to be reported.
  # @return [Array<String>]
  def check_validity = raise NotImplementedError

  # Raise a Suma::Payment::Invalid error with the messages from check_validity.
  def check_validity!
    msgs = self.check_validity
    return if msgs.empty?
    raise Suma::Payment::Invalid.new("Payment could not be created: #{msgs.join(', ')}", reasons: msgs)
  end

  # Return a hash of labels and values to display in admin.
  def admin_details = raise NotImplementedError

  # True if the strategy type supports issuing refunds.
  def supports_refunds? = false

  # Something like the last-4 of the card, or 'Off Platform'.
  # # @return [String]
  def originating_instrument_label = raise NotImplementedError

  # Return true if we are ready to initiate
  # a debit from an external account to a credit to our platform account.
  # This could be things like checking to make sure funds are available in the external account.
  def ready_to_collect_funds? = raise NotImplementedError

  # Start a payment with the given details.
  # This method must be idempotent.
  # In the case of being unable to collect funds, one of two exceptions should be raised:
  # - Suma::Payment::FundingTransaction::CollectionFailed when the payment should move into a 'needs review' state,
  # - Any other exception type, in which case the collection will be retried.
  def collect_funds = raise NotImplementedError

  # Return true if our payment processor believes the funds have 'cleared'-
  # that is, the ACH debit we originated has shown up in our account
  # as an ACH credit.
  def funds_cleared? = raise NotImplementedError

  # Return true if our payment processor has canceled or returned the funds.
  # For example, Stripe has refunded a credit card charge.
  # Implies no movement of money ended up taking place: it never ended up happening,
  # or happened and was reversed.
  def funds_canceled? = raise NotImplementedError

  # Return true if one of the state transition methods has called +flag_for_review+.
  # The state machines should move this instance into a 'needs review' state.
  def flagging_for_review? = @flagging_for_review

  def flag_for_review
    @flagging_for_review = true
  end
end
