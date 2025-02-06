# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/async"
require "suma/message/signalwire_webhookdb_optout_processor"

class Suma::Async::SignalwireProcessOptouts
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * *"
  splay 60

  def _perform
    return unless Suma::Message::SignalwireWebhookdbOptoutProcessor.configured?
    Suma::Message::SignalwireWebhookdbOptoutProcessor.new(now: Time.now).run
  end
end
