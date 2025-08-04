# frozen_string_literal: true

require "suma/external_links"
require "suma/payment/payout_transaction"

module Suma::Payment::PayoutTransaction::Strategy
  include Suma::ExternalLinks

  # Return a string that summarizes the strategy.
  # Use whatever is most useful for an admin to see,
  # it does not have to be totally unambiguous.
  def short_name = raise NotImplementedError

  # Return a hash of labels and values to display in admin.
  def admin_details = raise NotImplementedError

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

  # Return true if we are ready to start sending funds from our platform account to an external destination.
  def ready_to_send_funds? = raise NotImplementedError

  # Start sending funds with the given details.
  # This method must be idempotent.
  # It should return true the 'first time' through to the end of the function;
  # in other cases, such as an idempotent call, it should return false.
  # In the case of being unable to send funds, one of two exceptions should be raised:
  # - Suma::Payment::PayoutTransaction::SendingFailed when the payment should move into a 'needs review' state,
  # - Any other exception type, in which case the sending will be retried.
  def send_funds = raise NotImplementedError

  # Return true if our payment processor believes the funds have finished sending,
  # such as an ACH debit we originated from our platform account has likely settled
  # in an external ACH account.
  def funds_settled? = raise NotImplementedError
end
