# frozen_string_literal: true

require "rack/attack"
require "suma/redis"

class Rack::RackAttack
  def initialize(app)
    @app = app
  end

  def call(env)
    # Calling env exposes the needed api data like phone number
    @env = env
    response = @app.call(env)
    path = env["PATH_INFO"]
    method = env["REQUEST_METHOD"]
    # TODO: This is not reliable, must be fetched at the throttle block, but unsure how to
    phone = env["api.request.body"]["phone"]

    # TODO: Apply and test exponential back-off throttling layer
    # https://github.com/rack/rack-attack/blob/main/docs/advanced_configuration.md

    # The blocks returns the discriminator as phone and IP
    # This prevents malicious actors from disallowing member logins from other IPs
    if path.include?("/auth/start") && method === "POST"
      Rack::Attack.throttle("/auth/start", limit: 4, period: 1.minute) do |req|
        Suma::PhoneNumber::US.normalize(phone) + req.ip
      end
    end

    # Same as above but for /auth/verify endpoint
    if path.include?("/auth/verify") && method === "POST"
      Rack::Attack.throttle("/auth/verify", limit: 4, period: 1.minute) do |req|
        Suma::PhoneNumber::US.normalize(phone) + req.ip
      end
    end

    # Instead of passing retry-after through header, we pass it to
    # the response body, this makes it easier to fetch at the frontend level
    Rack::Attack.throttled_responder = lambda do |req|
      match_data = req.env["rack.attack.match_data"]
      now = Time.now.to_i
      retry_after = match_data[:period] - (now % match_data[:period])
      headers = {"Content-Type" => "application/json"}
      body = {error: {status: 429, retry_after: retry_after.to_s, code: "too_many_requests"}}
      return [429, headers, [body.to_json]]
    end

    return response
  end
end
