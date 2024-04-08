# frozen_string_literal: true

require "amigo/job"

class Suma::Async::AnalyticsDispatch
  extend Amigo::Job

  on "suma.*"

  def _perform(event)
    prefix, _sep, action = event.name.rpartition(".")
    return unless ["created", "updated", "destroyed"].include?(action)
    model_class = Suma::Postgres::Model.descendants.find { |d| d.event_prefix == prefix }
    raise Suma::InvalidPrecondition, "cannot find model for #{prefix}" if model_class.nil?

    if action == "destroyed"
      Suma::Analytics.destroy_from_transactional_model(model_class, event.payload[0])
      return
    end

    oltp_model = self.lookup_model(model_class, event)
    Suma::Analytics.upsert_from_transactional_model(oltp_model)
  end
end
