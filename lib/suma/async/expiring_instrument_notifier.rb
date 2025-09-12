# frozen_string_literal: true

require "amigo/job"

class Suma::Async::ExpiringInstrumentNotifier
  extend Amigo::Job

  def perform(member_id)
    member = self.lookup_model(Suma::Member, member_id)
    now = Time.now
    Suma::Idempotency.every(2.months).under_key("expiring -instrument-notifier-#{member.id}") do
      # Update the instrument from Stripe or wherever.
      # If we're now not expiring (Stripe updated the card, the card is deleted, etc.), then noop.
      Suma::Payment::Instrument.
        where(legal_entity_id: member.legal_entity_id).
        expired_as_of(now + 6.months).
        not_soft_deleted.map(&:reify).each do |pi|
        pi.refetch_remote_data
        pi.save_changes
      end
      return if Suma::Member.for_alerting_about_expiring_payment_instruments(now).where(id: member.id).empty?
      msg = Suma::Messages::SingleValue.new("payments", "expiring_instrument", nil)
      member.message_preferences!.dispatch(msg)
    end
  end
end
