# frozen_string_literal: true

require "suma/yosoy"

module Suma::Service::Auth
  __ = 0

  class Middleware < Suma::Yosoy::Middleware
    def serialize_into_session(session, _env) = session.token

    def serialize_from_session(key, _env)
      Suma::Member::Session.dataset.valid[token: key]
    end

    def inactivity_timeout
      Suma::Service.max_session_age
    end
  end
end
