# frozen_string_literal: true

require 'rack/session'

# Bare-bones Rack-based authentication library.
# After a decade of using Warden and Grape we decided to just write our auth system for our needs.
# This just manages authentication, not authorization,
# and does not manage application-level concerns like OTPs, password reset, etc.
class Suma::Yosoy
  class Error < StandardError; end
  class UnhandledReason < Error; end

  class << self
    attr_accessor :_on_next_request

    # Set a callback to run on the next request.
    # Callback is invoked with the +Proxy+.
    # Usually used to log in or out during testing.
    def on_next_request(&block)
      @_on_next_request ||= []
      @_on_next_request << block
    end
  end

  # Subclassable Rack middleware for using Yosoy.
  # The middleware creates an instance of +Proxy+ and injects it into the `env` of each request.
  #
  # Subclasses must override:
  # - +serialize_into_session+ (see docs)
  # - +serialize_from_session+ (see docs)
  #
  # Subclasses can override:
  # - +env_key+ and +throw_key+ to use different keys in the Rack environment, and for throw/catch,
  #   if somehow the defaults of "yosoy" and :yosoy are a problem.
  # - +inactivity_timeout+ if sessions should expire after a period of inactivity.
  # - User code can use `throw(:yosoy, :somemethod)` (or +proxy.throw!(:somemethod)+),
  #   which will call +Middleware#somemethod+, to return a particular error response.
  # - +response+ to return a different response. By default, responses are JSON,
  #   with a body like `{error: {status: <integer>}}`.
  #
  # Most usage of +Yosoy+ is:
  # - Calling +env['yosoy']+ to get a +Proxy+.
  # - Calling +Proxy#unauthenticated!+ to return a 401.
  #   - Use +Proxy#unauthenticated!(x: 1)+ to add the additional params as additional error keys,
  #     so the response body would be `{error: {status: 401, x: 1}}`.
  # - Calling +Proxy#set_authenticated_object+ to set the authentication object, like a user or DB session.
  # - Calling +Proxy#authenticated_object?+ to get the current authentication object, or nil.
  # - Calling +Proxy#authenticated_object!+ to get the current authenticationobject", or throw a 401.
  # - Calling +Proxy#logout+ on logout.
  class Middleware
    def initialize(app)
      @app = app
    end

    # Used for environment lookup, like `env['yosoy']`
    def env_key = "yosoy"

    # Key for use in `throw(:yosoy)` that is caught by the middleware.
    def throw_key = :yosoy

    # Seconds after which a session will no longer be used,
    # usually the same as a cookie expiration if using cookies.
    # Nil to disable the inactivity timeout.
    def inactivity_timeout = nil

    # Serialize the authenticated object (user, db session, etc) into the Rack session.
    # Usually just use a key, like +auth_object.id+ or +auth_object.token+.
    def serialize_into_session(_auth_object, _env) = raise NotImplementedError("Something like `auth_object.token`")
    # Deserialize the authenticated object key (user id, db session token, etc) into an actual authenticated object.
    # Usually a lookup, like +User[id: key]+ or +DbSession[token: key]+.
    def serialize_from_session(_key, _env) = raise NotImplementedError("Something like `DbSession[token: key]`")

    def call(env)
      proxy = Proxy.new(self, env)
      env[self.env_key] = proxy
      result = catch(self.throw_key) do
        Suma::Yosoy._on_next_request&.each do |cb|
          cb.call(proxy)
        end
        Suma::Yosoy._on_next_request&.clear
        @app.call(env)
      end
      case result
        when nil
          reason = :unauthenticated
          extra = {}
        when Hash
          reason = result.delete(:reason)
          extra = result
        when Symbol
          extra = {}
          reason = result
      else
          return result
      end
      unless self.respond_to?(reason)
        msg = "#{self.class.name || 'Your custom Yosoy middleware'} does not support the thrown reason :#{reason}. " \
              "Use a supported reason (like :unauthenticated), " \
              "or implement the method ##{reason} to return a Rack response."
        raise UnhandledReason, msg
      end
      response = self.send(reason, **extra)
      return response
    end

    def response(status_code, extra={})
      headers = {
        Rack::CONTENT_TYPE => "application/json",
      }
      body = {error: {status: status_code, **extra}}
      return [
        status_code,
        headers,
        [body.to_json],
      ]
    end

    def unauthenticated(**extra) = response(401, {code: "unauthenticated", **extra})
  end

  class Proxy
    attr_accessor :middleware, :env

    def initialize(middleware, env)
      @middleware = middleware
      @env = env
      @auth_ran = false
      @auth_obj = nil
      @last_access_set = false
    end

    def rack_session
      return @rack_session ||= @env["rack.session"]
    end

    def reset!
      @auth_ran = false
      @auth_obj = nil
      @last_access_set = false
    end

    # @return [nil,Object]
    def authenticated_object?
      return @auth_obj if @auth_ran
      key = self.rack_session["yosoy.key"]
      return nil if key.nil?
      @auth_obj = @middleware.serialize_from_session(key, @env)
      self._check_last_access
      self._mark_last_access
      @auth_ran = true
      return @auth_obj
    end

    def authenticated_object!
      ao = self.authenticated_object?
      self.unauthenticated! if ao.nil?
      return ao
    end

    def set_authenticated_object(object)
      key = @middleware.serialize_into_session(object, @env)
      self.rack_session["yosoy.key"] = key
      self._mark_last_access
    end

    def unauthenticated!(**kw)
      self.throw!(:unauthenticated, **kw)
    end

    def throw!(reason, **kw)
      throw(@middleware.throw_key, {reason:, **kw})
    end

    # Store the 'last access' timestamp for this scope session, and refresh it on every authed request.
    # If the timestamp is too old, reject the session.
    # This avoids a replay attack using an old cookie; even though the cookie itself gets an expires_at,
    # it can still be reused by an attacker later. Since the contents of the cookie are encrypted,
    # they cannot modify the last_access value stored in the session.
    def _mark_last_access
      return if @last_access_set
      self.rack_session["yosoy.last_access"] = Time.now.iso8601
    end

    def _check_last_access
      return if self.middleware.inactivity_timeout.nil?
      ts = self.rack_session["yosoy.last_access"]
      # If there is no last_access timestamp, this is the initial session auth,
      # or it's a legacy cookie that didn't store a timestamp.
      # Since we don't want to log everyone out when this ships,
      # we allow these legacy sessions to be used initially.
      return if ts.nil?
      ts = Time.parse(ts)
      expire_at = ts + self.middleware.inactivity_timeout
      return unless Time.now > expire_at
      self.logout
      self.unauthenticated!(message: "Cookie expired")
    end

    def logout
      self.rack_session.keys.select { |k| k.start_with?("yosoy.") }.to_a.each do |key|
        self.rack_session.delete(key)
      end
      self.reset!
    end
  end

  # Middleware that fails authentication if the callback proc returns falsy.
  # Block is called with a +Proxy+.
  class BlockAuthenticatorMiddleware
    def initialize(callback)
      @callback = callback
      @app = nil
    end

    def env_key = "yosoy"

    def new(app)
      @app = app
      return self
    end

    def call(env)
      proxy = env.fetch(self.env_key)
      ok = @callback.call(proxy)
      proxy.unauthenticated! unless ok
      return @app.call(env)
    end
  end
end
