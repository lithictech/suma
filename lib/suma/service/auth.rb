# frozen_string_literal: true

require "suma/yosoy"

module Suma::Service::Auth
  class LegacySessionAdapterMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      rack_session = env["rack.session"]
      if (legacy_member_key = rack_session["warden.user.member.key"])
        if (member = Suma::Member[legacy_member_key])
          dbsession = member.add_session(**Suma::Member::Session.params_for_request(Rack::Request.new(env)))
          rack_session["yosoy.key"] = dbsession.token
        end
        rack_session.delete("warden.user.member.key")
      end
      @app.call(env)
    end
  end

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
