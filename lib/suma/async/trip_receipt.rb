# frozen_string_literal: true

require "amigo/job"
require "suma/messages/trip_receipt"

class Suma::Async::TripReceipt
  extend Amigo::Job

  # Do not send receipts for trips ended more than 2 hours ago,
  # it'd be confusing and it can easily happen during backfilling.
  CUTOFF = 2.hours

  on(/suma\.mobility\.trip\.(created|updated)/)

  def _perform(event)
    trip = self.lookup_model(Suma::Mobility::Trip, event)
    return unless trip.ended?
    return if trip.ended_at < CUTOFF.ago
    # Don't bother checking for 'ended_at changed from nil' or whatever,
    # the cutoff and idempotency is enough.
    Suma::Idempotency.once_ever.under_key("trip-#{trip.id}-receipt") do
      msg = Suma::Messages::TripReceipt.new(trip)
      trip.member.message_preferences!.dispatch(msg)
    end
  end
end
