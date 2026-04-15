# frozen_string_literal: true

require "amigo/job"
require "suma/payment/reviewer"

# Process payments put into review.
class Suma::Async::PaymentReviewer
  extend Amigo::Job

  on(/suma\.payment\.(fundingtransaction|payouttransaction)\.updated/)

  def _perform(event)
    begin
      tx = self.lookup_model(Suma::Payment::FundingTransaction, event)
    rescue StandardError
      tx = self.lookup_model(Suma::Payment::PayoutTransaction, event)
    end
    case event.payload[1]
      when changed(:status, to: "needs_review")
        Suma::Payment::Reviewer.new(tx).act
    end
  end
end
