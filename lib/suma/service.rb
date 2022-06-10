# frozen_string_literal: true

require "appydays/configurable"
require "grape"
require "appydays/loggable"
require "pg"
require "sentry-ruby"
require "sequel"
require "sequel/adapters/postgres"
require "set"
require "warden"

require "suma"

# Service is the base class for all endpoint/resource classes.
class Suma::Service < Grape::API
  extend Suma::MethodUtilities
  include Appydays::Configurable
  include Appydays::Loggable

  require "suma/service/auth"
  require "suma/service/middleware"
  require "suma/service/types"
  require "suma/service/validators"

  # Name of the session in the server response cookie.
  # Note that it is always 'rack.session' in code though.
  SESSION_COOKIE = "suma.session"
  DEFAULT_CORS_ORIGINS = [/localhost:\d+/, /192\.168\.\d{1,3}\.\d{1,3}:\d{3,5}/].freeze
  SHORT_PAGE_SIZE = 20
  PAGE_SIZE = 100

  configurable(:service) do
    setting :max_session_age, 30.days.to_i

    # Note that changing the secret would invalidate all existing sessions!
    setting :session_secret, "Tritiphamhockbiltongpigporkchoptbonebeefsala" \
                             "michickenmeatballKielbasajowldrumstickbeefri" \
                             "bsfiletmignonbiltongPorkbellyballtipbacontai" \
                             "lgroundroundshankDrumstickcornedbeefbiltongp" \
                             "ancettaTbone"

    # Must be nil/unset on localhost, otherwise set to something.
    setting :cookie_domain, ""

    setting :devmode, false

    setting :enforce_ssl, true

    setting :cors_origins, [],
            convert: lambda { |origin_str|
              origin_str.split.map { |s| %r{/.+/}.match?(s) ? Regexp.new(s[1..-2]) : s }
            }

    setting :endpoint_caching, false

    after_configured do
      self.cors_origins += DEFAULT_CORS_ORIGINS
    end
  end

  # Return the config for the Rack::Session::Cookie middleware.
  def self.cookie_config
    return {
      key: Suma::Service::SESSION_COOKIE,
      domain: Suma::Service.cookie_domain,
      path: "/",
      expire_after: Suma::Service.max_session_age,
      secret: Suma::Service.session_secret,
      coder: Rack::Session::Cookie::Base64::ZipJSON.new,
    }
  end

  def self.decode_cookie(s)
    cfg = self.cookie_config
    s = s.delete_prefix(cfg[:key] + "=")
    return cfg[:coder].decode(Rack::Utils.unescape(s))
  end

  ### Build the Rack app according to the configured environment.
  def self.build_app
    inner_app = self
    builder = Rack::Builder.new do
      Suma::Service::Middleware.add_middlewares(self)
      run inner_app
    end
    return builder.to_app
  end

  def self.error_body(status, message, code: nil, more: {})
    error = more.merge(
      message:,
      status:,
    )
    error[:code] = code unless code.nil?
    return {error:}
  end

  Grape::Middleware::Auth::Strategies.add(:admin, Suma::Service::Auth::Admin)

  # Add some context to Sentry on each request.
  before do
    customer = current_customer?
    admin = admin_customer?
    Sentry.configure_scope do |scope|
      sentry_tags = {
        agent: env["HTTP_USER_AGENT"],
        host: env["HTTP_HOST"],
        method: env["REQUEST_METHOD"],
        path: env["PATH_INFO"],
        query: env["QUERY_STRING"],
        referrer: env["HTTP_REFERER"],
      }
      sentry_user = {ip_address: request.ip}
      if customer
        sentry_user.merge!(
          id: customer.id,
          email: customer.email,
          name: customer.name,
          ip_address: request.ip,
        )
        sentry_tags["customer.email"] = customer.email
      end
      if admin
        sentry_user.merge!(
          admin_id: admin.id,
          admin_email: admin.email,
          admin_name: admin.name,
        )
        sentry_tags["admin.email"] = admin.email
      end
      scope.set_user(sentry_user)
      sentry_tags.delete_if { |_, v| v.blank? }
      scope.set_tags(sentry_tags)
    end

    Suma.set_request_user_and_admin(customer, admin)
  end

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    # We can flesh this out with more details later:
    # https://github.com/ruby-grape/grape#validation-errors
    # https://stripe.com/docs/api/curl#errors
    invalid!(e.full_messages, message: e.message)
  end

  rescue_from Suma::Customer::InvalidPassword do |e|
    invalid!(e.message)
  end

  rescue_from Grape::Exceptions::MethodNotAllowed do |e|
    error!(e.message, 405)
  end

  rescue_from Suma::LockFailed do |_e|
    merror!(
      409,
      "Attempting to lock the resource failed. You should fetch a new version of the resource and try again.",
      code: "lock_failed",
    )
  end

  rescue_from Suma::Customer::ReadOnlyMode do |e|
    merror!(
      409,
      "Customer is in read-only mode and cannot be updated: #{e.message}",
      code: e.message,
    )
  end

  rescue_from :all do |e|
    status = e.respond_to?(:status) ? e.status : 500
    error_id = SecureRandom.uuid
    error_signature = Digest::MD5.hexdigest("#{e.class}: #{e.message}")

    Suma::Service.logger.error "[%s] Uncaught %p in service: %s" %
      [error_id, e.class, e.message]
    Suma::Service.logger.debug { e.backtrace.join("\n") }
    if ENV["PRINT_API_ERROR"]
      puts e
      puts e.backtrace
    end

    more = {error_id:, error_signature:}

    if Suma::Service.devmode
      msg = e.message
      more[:backtrace] = e.backtrace.join("\n")
    else
      Sentry.capture_exception(e, tags: more) if Suma::Sentry.enabled?
      msg = "An internal error occurred of type #{error_signature}. Error ID: #{error_id}"
    end
    Suma::Service.logger.error("api_exception", {error_id:, error_signature:}, e)
    merror!(status, msg, code: "api_error", more:)
  end

  finally do
    Suma.set_request_user_and_admin(nil, nil)
  end
end
