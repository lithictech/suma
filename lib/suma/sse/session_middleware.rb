# frozen_string_literal: true

require "suma/sse"

# Middleware for endpoints using Server Sent Events.
#
# The endpoints should:
#
# - Return an event subscription auth token in some GET endpoint (usually the list or resource being subscribed to)
# - Include that auth token in all mutating methods using the same header.
# - Any events that happen during a reuqest using that auth token, will not be published to the subscriber
#   registered with that token. This avoids notifying about an action the user took, in the same browser window.
#
# NOTE: This must be a middleware, NOT a before/finally Grape hook, since it needs to run AFTER any
# entity rendering (since entity rendering could cause side effects).
class Suma::SSE::SessionMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    route = env.fetch("api.endpoint")
    header_check = Suma::Http::UNSAFE_METHODS.include?(env["REQUEST_METHOD"]) &&
      !route.route_setting(:do_not_check_sse_token)
    session_header_val = env.fetch(Suma::SSE::TOKEN_RACK_HEADER, nil)
    if header_check && session_header_val.nil?
      # If we are taking an action that would result in an update, make sure the caller has included
      # an event token so we don't replay events back to the client.
      body = {
        error: {
          message: "Endpoint uses Server Sent Events so requires a '#{Suma::SSE::TOKEN_HEADER}' header",
          code: "missing_sse_token",
        },
      }
      return [400, {"Content-Type" => "application/json"}, [body.to_json]]
    end
    Suma::SSE.current_session_id = session_header_val
    begin
      status, headers, body = @app.call(env)
    ensure
      Suma::SSE.current_session_id = nil
    end
    return status, headers, body
  end
end
