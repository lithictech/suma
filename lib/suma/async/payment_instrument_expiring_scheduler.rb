# frozen_string_literal: true

require "amigo/scheduled_job"

require "suma/async/payment_instrument_expiring_notifier"

# Each week, look for payment instruments set to expire.
# For each member, enqueue a job so that they get a text message
# between 10am-1pm local time.
class Suma::Async::PaymentInstrumentExpiringScheduler
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "0 1 * * 4" # 01:00 every Thursday. Timezone doesn't matter.
  splay 60.seconds

  NOTIFY_HOURS = 10..14
  NOTIFY_DOW = :thursday

  def _perform
    Suma::Member.for_alerting_about_expiring_payment_instruments(Time.now).each do |m|
      perform_at = self.class.schedule_notifier_for(m)
      # It's okay that we may enqueue multiple notifications for the same user.
      # The notifier has proper idempotency.
      Suma::Async::PaymentInstrumentExpiringNotifier.perform_at(perform_at, m.id)
    end
  end

  def self.schedule_notifier_for(member)
    now = Time.now.in_time_zone(member.timezone)
    hour = rand(NOTIFY_HOURS)
    minute = rand(0..59)
    target = now.change(hour:, minute:)
    target += 1.day until target.send("#{NOTIFY_DOW}?")
    return target
  end
end
