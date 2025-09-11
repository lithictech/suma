# frozen_string_literal: true

require "amigo/job"

class Suma::Async::ExpiringInstrumentNotifier
  extend Amigo::Job

  def perform(member_id)
    member = self.lookup_model(Suma::Member, member_id)
    Suma::Idempotency.every(2.months).under_key("expiring -instrument-notifier-#{member.id}") do
      return if Suma::Member.for_alerting_about_expiring_payment_instruments(Time.now).where(id: member.id).empty?
      msg = Suma::Messages::SingleValue.new("payments", "expiring_instrument", nil)
      member.message_preferences!.dispatch(msg)
    end
  end
end
