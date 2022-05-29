# frozen_string_literal: true

require "suma/postgres/model"

module Suma::Payment::FundingTransaction::Strategy
  # Return a string that summarizes the strategy.
  # Use whatever is most useful for an admin to see,
  # it does not have to be totally unambiguous.
  def short_name
    raise NotImplementedError
  end

  # Return true if we are ready to initiate
  # a debit from an external account to a credit to our platform account.
  # This could be things like checking to make sure funds are available in the external account.
  def ready_to_collect_funds?
    raise NotImplementedError
  end

  # Start a payment with the given details.
  # This method must be idempotent.
  # It should return true the 'first time' through to the end of the function;
  # in other cases, such as an idempotent call, it should return false.
  # In the case of being unable to collect funds, one of two exceptions should be raised:
  # - Suma::Payment::FundingTransaction::CollectionFailed when the payment should move into a 'needs review' state,
  # - Any other exception type, in which case the collection will be retried.
  def collect_funds
    raise NotImplementedError
  end

  # Return true if our payment processor believes the funds have 'cleared'-
  # that is, the ACH debit we originated has shown up in our account
  # as an ACH credit.
  def funds_cleared?
    raise NotImplementedError
  end
end
