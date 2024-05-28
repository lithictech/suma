# frozen_string_literal: true

require "suma/yosoy"

module Suma::Service::Auth
  X = 1

  class Middleware < Suma::Yosoy::Middleware
    def serialize_into_session(session, _env) = session.token

    # TODO: Support legacy sessions
    # else
    #   # Legacy sessions used member id as the key. Find or create a session.
    #   if (member = Suma::Member[key])
    #     member.sessions_dataset.order(:created_at).last ||
    #       member.add_session(**Suma::Member::Session.params_for_request(Rack::Request.new(env)))
    #   end
    # end

    def serialize_from_session(key, _env)
      Suma::Member::Session.dataset.valid[token: key]
    end

    def inactivity_timeout
      Suma::Service.max_session_age
    end
  end
end
