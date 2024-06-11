# frozen_string_literal: true

require "rack"

# Add headers to a response.
class Rack::SimpleHeaders
  def initialize(app, headers, defaults: {})
    @app = app
    @headers = headers
    @defaults = defaults
  end

  def call(env)
    status, headers, body = @app.call(env)
    h = @defaults.merge(headers).merge(@headers)
    return [status, h, body]
  end
end
