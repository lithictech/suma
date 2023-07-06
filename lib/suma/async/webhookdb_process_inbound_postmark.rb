# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/redis"
require "suma/webhookdb"

class Suma::Async::WebhookdbProcessInboundPostmark
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/#{Suma::Async.cron_poll_interval - 2} * * * * *"
  splay nil

  CACHE_KEY = "process-inbound-postmark-pk"

  def _perform
    pmrelay = Suma::AnonProxy::Relay.create!("postmark")
    # It's a little tricky to avoid processing the same row twice.
    # For now, we store the highest PK of the seen rows.
    last_synced_pk = Suma::Redis.cache.with { |c| c.call("GET", CACHE_KEY) }
    last_synced_pk = last_synced_pk.to_i
    highest_pk = last_synced_pk
    Suma::Webhookdb.postmark_inbound_messages_dataset.where { pk > last_synced_pk }.each do |row|
      highest_pk = [highest_pk, row[:pk]].max
      message = pmrelay.parse_message(row)
      Suma::AnonProxy::MessageHandler.handle(pmrelay, message)
    end
    Suma::Redis.cache.with { |c| c.call("SET", CACHE_KEY, highest_pk.to_s) }
  end
end
