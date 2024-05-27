# frozen_string_literal: true

# Bare-bones Rack-based authentication library.
# After a decade of using Warden and Grape we decided to just write our auth system for our needs.
# This just manages authentication, not authorization,
# and does not manage application-level concerns like OTPs, password reset, etc.
class Suma::Yosoy
  class << self
    attr_accessor :_on_next_request

    def on_next_request(&block)
      @_on_next_request ||= []
      @_on_next_request << block
    end
  end

  # Subclassable middleware class.
  # If throw(:yosoy, :somemethod) is used, the #somemethod method will be called to get the response.
  # You can also override #response to provide a different response shape.
  class Middleware
    def initialize(app)
      @app = app
      @_on_next_request = []
    end

    # Used for environment lookup, like `env['yosoy']`
    def env_key = "yosoy"

    # Key for use in `throw(:yosoy)` that is caught by the middleware.
    def throw_key = :yosoy

    # Seconds after which a session will no longer be used,
    # usually the same as a cookie expiration if using cookies.
    # Nil to disable the inactivity timeout.
    def inactivity_timeout = nil

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
        when Hash
          tag = result.delete(:tag)
          extra = result
        when Symbol
          extra = {}
          tag = result
      else
          return result
      end
      response = self.send(tag, **extra)
      return response
    end

    def response(status_code, extra={})
      headers = {
        "Content-Type" => "application/json",
      }
      body = {error: {status: status_code, **extra}}
      return [
        status_code,
        headers,
        [body.to_json],
      ]
    end

    def unauthenticated(**extra) = response(401, {code: "unauthenticated", **extra})

    def serialize_into_session(_user) = raise NotImplementedError("Something like `user.id`")
    def serialize_from_session(_key) = raise NotImplementedError("Something like `User[key]`")

    # Rack session key for Yosoy.
    def session_key(scope) = "yosoy.sessions.#{scope}"

    #   # Store the 'last access' timestamp for this user session, and refresh it on every request.
    #   # If the timestamp is too old, reject the session.
    #   # This avoids a replay attack using an old cookie; even though the cookie itself gets an expires_at,
    #   # it can still be reused by an attacker later. Since the contents of the cookie are encrypted,
    #   # they cannot modify the last_access value stored in the session.
    #   scope = opts[:scope]
    #   # If there is no last_access timestamp, this is the initial session auth, or it's a legacy cookie (pre-May 2024).
    #   # Since we don't want to log everyone out when this ships, we allow these legacy sessions to continue.
    #   if (ts = auth.session(scope)["last_access"])
    #     ts = Time.parse(ts)
    #     expire_at = ts + Suma::Service.max_session_age
    #     if Time.now > expire_at
    #       auth.logout(scope)
    #       throw(:warden, scope:, reason: "Cookie expired")
    #     end
    #   end
    #   auth.session(scope)["last_access"] = Time.now.iso8601
  end

  class Proxy
    attr_accessor :middleware, :env

    def initialize(middleware, env)
      @middleware = middleware
      @env = env
      @auth_ran = {}
      @authed_users = {}
      @last_access_set = false
    end

    def rack_session
      return @rack_session ||= @env["rack.session"]
    end

    def reset!
      @auth_ran.clear
      @authed_users.clear
      @last_access_set = false
    end

    def authenticated?(scope)
      return @authed_users[scope] if @auth_ran[scope]
      key = self.get_session_value(scope, "key")
      return nil if key.nil?
      user = @middleware.serialize_from_session(key)
      @authed_users[scope] = user
      @auth_ran[scope] = true
      self._check_last_access
      self._mark_last_access
      return user
    end

    def authenticated!(scope)
      u = self.authenticated?(scope)
      self.unauthenticated! if u.nil?
      return u
    end

    def set_user(user, scope)
      self.set_session_value(scope, "key", @middleware.serialize_into_session(user))
    end

    def unauthenticated!(**kw)
      self.throw!(:unauthenticated, **kw)
    end

    def throw!(tag, **kw)
      throw(@middleware.throw_key, {tag:, **kw})
    end

    def get_session_value(scope, key, default=nil)
      session = _get_session(scope)
      return default if session.nil?
      return session.fetch(key, default)
    end

    def set_session_value(scope, key, value)
      if (session = _get_session(scope)).nil?
        session = {}
        self.rack_session[self.middleware.session_key(scope)] = session
      end
      session[key] = value
      session
    end

    def delete_session_value(scope, key)
      session = _get_session(scope)
      return if session.nil?
      session.delete(key)
    end

    def _get_session(scope)
      return self.rack_session[self.middleware.session_key(scope)]
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
      # If there is no last_access timestamp, this is the initial session auth, or it's a legacy cookie.
      # Since we don't want to log everyone out when this ships, we allow these legacy sessions to continue.
      return if ts.nil?
      ts = Time.parse(ts)
      expire_at = ts + self.middleware.inactivity_timeout
      return unless Time.now > expire_at
      self.logout
      self.unauthenticated!(reason: "Cookie expired")
    end

    def logout(*scopes)
      if scopes.empty?
        self.rack_session.keys.select { |k| k.start_with?("yosoy.") }.to_a.each do |key|
          self.rack_session.delete(key)
        end
      else
        scopes.each do |scope|
          self.rack_session.delete(self.middleware.session_key(scope))
        end
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
    end

    def call(env)
      proxy = env.fetch(self.env_key)
      ok = @callback.call(proxy)
      proxy.unauthenticated! unless ok
      return @app.call(env)
    end
  end

  class Impersonation
    attr_reader :proxy

    def initialize(proxy)
      @proxy = proxy
    end

    def target_scope = raise NotImplementedError("Something like :user")
    def parent_scope = raise NotImplementedError("Something like :admin")

    def is?
      return false unless self.proxy.authenticated?(self.parent_scope)
      return self.proxy.get_session_value(self.parent_scope, "parent").present?
    end

    def target_user
      return self.proxy.authenticated!(self.target_scope)
    end

    def parent_user
      return self.proxy.authenticated!(self.parent_scope)
    end

    def on(target)
      self.proxy.set_session_value(self.parent_scope, "parent", target.id)
      self.proxy.logout(self.target_scope)
      self.proxy.set_user(target, self.target_scope)
    end

    def off(parent)
      self.proxy.logout(self.target_scope)
      self.proxy.delete_session_value(self.parent_scope, "parent")
      self.proxy.set_user(parent, self.target_scope)
    end
  end
end
