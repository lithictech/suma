# frozen_string_literal: true

require "appydays/configurable"
require "warden"

class Suma::Service::Auth
  include Appydays::Configurable

  class PasswordStrategy < Warden::Strategies::Base
    def valid?
      params["password"] && (params["phone"] || params["email"])
    end

    def authenticate!
      member = self.lookup_member
      success!(member) if member
    end

    protected def lookup_member
      if params["phone"]
        member = Suma::Member.with_us_phone(params["phone"].strip)
        if member.nil?
          fail!("No member with that phone")
          return nil
        end
      else
        member = Suma::Member.with_email(params["email"].strip)
        if member.nil?
          fail!("No member with that email")
          return nil
        end
      end
      return member if member.authenticate(params["password"])
      fail!("Incorrect password")
      return nil
    end
  end

  class AdminPasswordStrategy < PasswordStrategy
    def authenticate!
      return unless (member = self.lookup_member)
      unless member.admin?
        fail!
        return
      end
      success!(member)
    end
  end

  # Create the middleware for a Warden auth failure.
  # Is not a 'normal' Rack middleware, which normally accepts 'app' in the initializer and has
  # 'call' as an instance method.
  # See https://github.com/wardencommunity/warden/wiki/Setup
  class FailureApp
    def self.call(env)
      warden_opts = env.fetch("warden.options", {})
      msg = warden_opts[:message] || env["suma.authfailuremessage"] || "Unauthorized"
      body = Suma::Service.error_body(401, msg)
      return 401, {"Content-Type" => "application/json"}, [body.to_json]
    end
  end

  # Middleware to use for Grape admin auth.
  # See https://github.com/ruby-grape/grape#register-custom-middleware-for-authentication
  class Admin
    def initialize(app, *_args)
      @app = app
    end

    def call(env)
      warden = env["warden"]
      member = warden.authenticate!(scope: :admin)

      unless member.admin?
        body = Suma::Service.error_body(401, "Unauthorized")
        return 401, {"Content-Type" => "application/json"}, [body.to_json]
      end
      return @app.call(env)
    end
  end

  Warden::Manager.serialize_into_session(&:id)
  Warden::Manager.serialize_from_session { |id| Suma::Member[id] }
  Warden::Manager.after_set_user do |_user, auth, opts|
    # Store the 'last access' timestamp for this user session, and refresh it on every request.
    # If the timestamp is too old, reject the session.
    # This avoids a replay attack using an old cookie; even though the cookie itself gets an expires_at,
    # it can still be reused by an attacker later. Since the contents of the cookie are encrypted,
    # they cannot modify the last_access value stored in the session.
    scope = opts[:scope]
    # If there is no last_access timestamp, this is the initial session auth, or it's a legacy cookie (pre-May 2024).
    # Since we don't want to log everyone out when this ships, we allow these legacy sessions to continue.
    if (ts = auth.session(scope)["last_access"])
      ts = Time.parse(ts)
      expire_at = ts + Suma::Service.max_session_age
      if Time.now > expire_at
        auth.logout(scope)
        throw(:warden, scope:, reason: "Cookie expired")
      end
    end
    auth.session(scope)["last_access"] = Time.now.iso8601
  end

  Warden::Strategies.add(:password, PasswordStrategy)
  Warden::Strategies.add(:admin_password, AdminPasswordStrategy)

  # Restore the /unauthenticated route to what it originally was.
  # This is an API, not a rendered app...
  Warden::Manager.before_failure do |env, opts|
    env["PATH_INFO"] = opts[:attempted_path]
  end

  def self.add_warden_middleware(builder)
    builder.use Warden::Manager do |manager|
      # manager.default_strategies :password
      manager.failure_app = FailureApp

      manager.scope_defaults(:member, strategies: [:password])
      manager.scope_defaults(:admin, strategies: [:admin_password])
    end
  end

  class Impersonation
    attr_reader :warden

    def initialize(warden)
      @warden = warden
    end

    def is?
      return false unless self.warden.authenticated?(:admin)
      return self.warden.session(:admin)["impersonating"].present?
    end

    def current_member
      return self.warden.authenticate!(scope: :member)
    end

    def admin_member
      return self.warden.authenticate!(scope: :admin)
    end

    def on(target_member)
      self.warden.session(:admin)["impersonating"] = target_member.id
      self.warden.logout(:member)
      self.warden.set_user(target_member, scope: :member)
    end

    def off(admin_member)
      self.warden.logout(:member)
      self.warden.session(:admin).delete("impersonating")
      self.warden.set_user(admin_member, scope: :member)
    end
  end
end
