# frozen_string_literal: true

require "rack"

# Set the Service-Worker-Allowed header to the given scope
# if this is a service worker request.
class Rack::ServiceWorkerAllowed
  def initialize(app, scope:)
    @app = app
    @scope = scope
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers["Service-Worker-Allowed"] = @scope if env["HTTP_SERVICE_WORKER"]
    return status, headers, body
  end
end
