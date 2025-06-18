# frozen_string_literal: true

require "rack/cors"
require "rack/protection"
require "rack/remote_ip"
require "rack/ssl-enforcer"
require "sentry-ruby"
require "appydays/loggable/request_logger"
require "sequel/sequel_translated_text"

require "suma/rack_attack"
require "suma/performance"

require "suma/service" unless defined?(Suma::Service)

module Suma::Service::Middleware
  def self.add_middlewares(builder)
    self.add_cors_middleware(builder)
    self.add_common_middleware(builder)
    self.add_dev_middleware(builder) if Suma::Service.devmode
    self.add_ssl_middleware(builder) if Suma::Service.enforce_ssl
    self.add_rate_limiting_middleware(builder)
    self.add_session_middleware(builder)
    self.add_security_middleware(builder)
    self.add_auth_middleware(builder)
    self.add_etag_middleware(builder)
    builder.use(RequestLogger)
    builder.use(Suma::Performance::RackMiddleware, logger: Suma::Service.logger)
  end

  def self.add_cors_middleware(builder)
    builder.use(Rack::Cors) do
      allow do
        origins(*Suma::Service.cors_origins)
        resource "*",
                 headers: :any,
                 methods: :any,
                 credentials: true,
                 expose: [
                   "Etag",
                   "Created-Resource-Id",
                   "Created-Resource-Admin",
                   "Suma-Current-Member",
                   "Suma-Events-Token",
                 ]
      end
    end
  end

  def self.add_common_middleware(builder)
    builder.use(Rack::ContentLength)
    builder.use(Rack::Chunked)
    builder.use(Rack::Deflater)
    builder.use(Sentry::Rack::CaptureExceptions)
    builder.use(Rack::RemoteIp)
    builder.use(SequelTranslatedText::RackMiddleware, languages: Suma::I18n.enabled_locale_codes.map(&:to_sym))
  end

  def self.add_dev_middleware(builder)
    builder.use(Rack::ShowExceptions)
    builder.use(Rack::Lint)
  end

  def self.add_ssl_middleware(builder)
    builder.use(Rack::SslEnforcer, redirect_html: false)
  end

  ### Add middleware for maintaining sessions to +builder+.
  def self.add_session_middleware(builder)
    builder.use Rack::Session::Cookie, Suma::Service.cookie_config
    builder.use(SessionReader)
  end

  ### Add security middleware to +builder+.
  def self.add_security_middleware(_builder)
    # session_hijacking causes issues in integration tests...?
    # builder.use Rack::Protection, except: :session_hijacking
  end

  def self.add_auth_middleware(builder)
    builder.use Suma::Service::Auth::Middleware
  end

  def self.add_etag_middleware(builder)
    builder.use Rack::ConditionalGet
    builder.use Rack::ETag
  end

  # Must initialize Rack::Attack rate limiting config here
  def self.add_rate_limiting_middleware(builder)
    builder.use Rack::Attack
  end

  # We always want a session to be written, even if noop requests,
  # so always force a write if the session isn't loaded.
  class SessionReader
    def initialize(app)
      @app = app
    end

    def call(env)
      env["rack.session"]["_"] = "_" unless env["rack.session"].loaded?
      @app.call(env)
    end
  end

  class RequestLogger < Appydays::Loggable::RequestLogger
    def request_tags(env)
      tags = super
      tags[:member_id] = env["yosoy"].authenticated_object?&.member_id || 0
      return tags
    end
  end
end
