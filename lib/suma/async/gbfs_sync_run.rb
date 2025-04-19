# frozen_string_literal: true

require "amigo/job"

class Suma::Async::GbfsSyncRun
  extend Amigo::Job

  def perform(feed_id, component)
    feed = self.lookup_model(Suma::Mobility::GbfsFeed, feed_id)
    return unless feed.component_enabled?(component)
    feed.sync_component(component)
  end
end
