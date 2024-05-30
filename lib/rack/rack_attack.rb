# frozen_string_literal: true

require "rack/attack"
require "suma/redis"

class Rack::RackAttack
  def initialize(app)
    @app = app
  end

  def call(env)
    # Rate limit auth/start by member normalized phone number and IP address
    # This prevents malicious actors from disallowing member logins from other IPs
    if env["PATH_INFO"].include?("/auth/start") && env["REQUEST_METHOD"] === "POST"
      Rack::Attack.throttle("/auth/start", limit: 10, period: 1.minute) do |req|
        Suma::PhoneNumber::US.normalize(req.params["phone"].to_s) + req.ip
      end
    end

    # TODO: increasing wait times between attempts, recommendation by deeparmor
    # Rate limit endpoint auth/verify by members normalized phone number and IP address
    if env["PATH_INFO"].include?("/auth/verify") && env["REQUEST_METHOD"] === "POST"
      Rack::Attack.throttle("/auth/verify", limit: 10, period: 1.minute) do |req|
        Suma::PhoneNumber::US.normalize(req.params["phone"].to_s) + req.ip
      end
    end

    # TODO: implement custom throttle response where 'retry-after' header
    # is set to progressive wait between attempts

    # TODO: use rack blocking to block ips for specific amount of time

    return @app.call(env)
  end
end
