# frozen_string_literal: true

require "rack/attack"

class Rack::AuthRateLimit < Rack::Attack
  Rack::Attack.throttle("/auth/start/phone_ip", limit: 5, period: 1.hour) do |req|
    self.throttle_block(req, "/auth/start")
  end

  Rack::Attack.throttle("/auth/verify", limit: 5, period: 1.hour) do |req|
    self.throttle_block(req, "/auth/verify")
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

  def self.throttle_block(request, check_path)
    if request.path.include?(check_path)
      params = JSON.parse(request.body.read)
      phone = Suma::PhoneNumber::US.normalize(params["phone"])
      request.body.rewind
      # Fetches test :header first, otherwise fallback to default ip
      ip = request.env["HTTP_REMOTE_ADDR"] || request.ip
      phone + ip
    end
  end
end
