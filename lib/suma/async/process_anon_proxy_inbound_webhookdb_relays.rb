# frozen_string_literal: true

require "amigo/scheduled_job"
require "amigo/advisory_locked"
require "suma/async"
require "suma/redis"
require "suma/webhookdb"

class Suma::Async::ProcessAnonProxyInboundWebhookdbRelays
  extend Amigo::ScheduledJob

  sidekiq_options(
    Suma::Async.cron_job_options.merge(
      advisory_lock: {db: Suma::Member.db, backoff: nil},
    ),
  )
  cron "*/#{Suma::Async.cron_poll_interval - 2} * * * * *"
  splay nil

  def relay_row_iterator(relay)
    # Store the highest PK of each relay row processed.
    pk_key = "process-anon-proxy-inbound-relays-#{relay.key}"
    return Suma::Webhookdb::RowIterator.new(pk_key)
  end

  def _perform
    Suma::AnonProxy::Relay.registry_each do |relay|
      next unless relay.webhookdb_dataset
      self.relay_row_iterator(relay).each(relay.webhookdb_dataset) do |row|
        message = relay.parse_message(row)
        Suma::AnonProxy::MessageHandler.handle(relay, message)
      end
    end
  end
end
