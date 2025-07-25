# frozen_string_literal: true

require "amigo/scheduled_job"
require "sequel/advisory_lock"
require "suma/async"
require "suma/redis"
require "suma/webhookdb"

class Suma::Async::ProcessAnonProxyInboundWebhookdbRelays
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/#{Suma::Async.cron_poll_interval - 2} * * * * *"
  splay nil

  def self.relay_cache_key(relay)
    # Store the highest PK of each relay row processed.
    return "process-anon-proxy-inbound-relays-#{relay.key}"
  end

  def advisory_lock(db: Suma::Member.db) = Sequel::AdvisoryLock.new(db, 2_000_123_654)

  def _perform
    # This can be enqueued from cron, and also explicitly, so it needs an exclusive lock.
    alock = self.advisory_lock
    performed, _ = alock.with_lock? do
      self._inner_perform
    end
    return if performed
    self.class.perform_in(3.seconds)
  end

  def _inner_perform
    Suma::AnonProxy::Relay.registry_each do |relay|
      next unless relay.webhookdb_dataset
      cache_key = self.class.relay_cache_key(relay)
      last_synced_pk = Suma::Redis.cache.with { |c| c.call("GET", cache_key) }.to_i
      highest_pk = last_synced_pk
      relay.webhookdb_dataset.where { pk > last_synced_pk }.each do |row|
        highest_pk = [highest_pk, row[:pk]].max
        message = relay.parse_message(row)
        Suma::AnonProxy::MessageHandler.handle(relay, message)
      end
      Suma::Redis.cache.with { |c| c.call("SET", cache_key, highest_pk.to_s) }
    end
  end
end
