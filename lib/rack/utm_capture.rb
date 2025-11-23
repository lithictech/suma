# frozen_string_literal: true

require "rack"

# Store utm_parameters (see +UTM_KEYS+) into cookies with the same name.
# This allows the backend to keep track of utm parameters for signups
# that occur some time later in the code on the frontend,
# reading them back from cookies.
# The frontend does not need to know anything about utm_parameters
# since storing them is handled transparently via cookies.
class Rack::UtmCapture
  UTM_KEYS = [
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "utm_term",
    "utm_content",
  ].freeze

  COOKIE_EXPIRES = 30.days.to_i

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    req = Rack::Request.new(env)
    utm_params = extract_utm_params(req)
    unless utm_params.empty?
      # Only modify response headers if new UTM params exist
      cookie_strings = build_cookie_values(utm_params, req)
      add_set_cookie_strings(headers, cookie_strings)
    end

    [status, headers, body]
  end

  private def extract_utm_params(req)
    return UTM_KEYS.each_with_object({}) do |key, acc|
      acc[key] = req.params[key] if req.params[key]
    end
  end

  # Build Set-Cookie headers (but avoid overwriting existing cookie if not needed)
  private def build_cookie_values(utm_params, req)
    existing_cookies = req.cookies

    utm_params.filter_map do |key, value|
      # Only set cookie if missing or value changed
      next if existing_cookies[key] == value

      cookie_value = Rack::Utils.escape(value)
      expires = Time.now + COOKIE_EXPIRES

      "#{key}=#{cookie_value}; path=/; expires=#{expires.httpdate}; SameSite=Lax"
    end
  end

  private def add_set_cookie_strings(headers, cookie_headers)
    return if cookie_headers.empty?
    # Ensure Set-Cookie is an array (Rack allows multiple Set-Cookie headers)
    existing = headers["Set-Cookie"]
    if existing.nil?
      headers["Set-Cookie"] = cookie_headers
    elsif existing.is_a?(Array)
      headers["Set-Cookie"].concat(cookie_headers)
    else
      headers["Set-Cookie"] = [existing] + cookie_headers
    end
  end
end
