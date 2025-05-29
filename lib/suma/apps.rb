# frozen_string_literal: true

require "amigo"
require "grape-swagger"
require "rack/builder"
require "rack/csp"
require "rack/dynamic_config_writer"
require "rack/lambda_app"
require "rack/service_worker_allowed"
require "rack/simple_headers"
require "rack/simple_redirect"
require "rack/spa_app"
require "rack/spa_rewrite"
require "url_shortener/rack_app"
require "sidekiq/web"

require "suma/api"
require "suma/async"
require "suma/service"
require "suma/api/auth"
require "suma/api/anon_proxy"
require "suma/api/commerce"
require "suma/api/images"
require "suma/api/ledgers"
require "suma/api/me"
require "suma/api/meta"
require "suma/api/mobility"
require "suma/api/payment_instruments"
require "suma/api/payments"
require "suma/api/preferences"
require "suma/api/surveys"
require "suma/api/system"
require "suma/api/webhookdb"

require "suma/admin_api/auth"
require "suma/admin_api/bank_accounts"
require "suma/admin_api/book_transactions"
require "suma/admin_api/charges"
require "suma/admin_api/commerce_offerings"
require "suma/admin_api/commerce_orders"
require "suma/admin_api/commerce_products"
require "suma/admin_api/commerce_offering_products"
require "suma/admin_api/funding_transactions"
require "suma/admin_api/members"
require "suma/admin_api/message_deliveries"
require "suma/admin_api/meta"
require "suma/admin_api/marketing_lists"
require "suma/admin_api/marketing_sms_broadcasts"
require "suma/admin_api/marketing_sms_dispatches"
require "suma/admin_api/mobility_trips"
require "suma/admin_api/organizations"
require "suma/admin_api/organization_memberships"
require "suma/admin_api/payment_ledgers"
require "suma/admin_api/payment_triggers"
require "suma/admin_api/payout_transactions"
require "suma/admin_api/programs"
require "suma/admin_api/program_enrollments"
require "suma/admin_api/roles"
require "suma/admin_api/search"
require "suma/admin_api/vendors"
require "suma/admin_api/vendor_services"
require "suma/admin_api/anon_proxy"

require "suma/url_shortener"

module Suma::Apps
  class API < Suma::Service
    mount Suma::API::System
    mount Suma::API::Auth
    mount Suma::API::AnonProxy
    mount Suma::API::Commerce
    mount Suma::API::Images
    mount Suma::API::Ledgers
    mount Suma::API::Me
    mount Suma::API::Meta
    mount Suma::API::Mobility
    mount Suma::API::PaymentInstruments
    mount Suma::API::Payments
    mount Suma::API::Preferences
    mount Suma::API::Surveys
    mount Suma::API::Webhookdb
    add_swagger_documentation(mount_path: "/swagger", info: {title: "Suma App API"}) if
      Suma::Service.swagger_enabled
  end

  class AdminAPI < Suma::Service
    mount Suma::AdminAPI::AnonProxy
    mount Suma::AdminAPI::Auth
    mount Suma::AdminAPI::BankAccounts
    mount Suma::AdminAPI::BookTransactions
    mount Suma::AdminAPI::Charges
    mount Suma::AdminAPI::CommerceOfferings
    mount Suma::AdminAPI::CommerceOrders
    mount Suma::AdminAPI::CommerceProducts
    mount Suma::AdminAPI::CommerceOfferingProducts
    mount Suma::AdminAPI::FundingTransactions
    mount Suma::AdminAPI::MarketingLists
    mount Suma::AdminAPI::MarketingSmsBroadcasts
    mount Suma::AdminAPI::MarketingSmsDispatches
    mount Suma::AdminAPI::Members
    mount Suma::AdminAPI::MessageDeliveries
    mount Suma::AdminAPI::Meta
    mount Suma::AdminAPI::MobilityTrips
    mount Suma::AdminAPI::Organizations
    mount Suma::AdminAPI::OrganizationMemberships
    mount Suma::AdminAPI::PaymentLedgers
    mount Suma::AdminAPI::PaymentTriggers
    mount Suma::AdminAPI::PayoutTransactions
    mount Suma::AdminAPI::Programs
    mount Suma::AdminAPI::ProgramEnrollments
    mount Suma::AdminAPI::Roles
    mount Suma::AdminAPI::Search
    mount Suma::AdminAPI::Vendors
    mount Suma::AdminAPI::VendorServices
    add_swagger_documentation(mount_path: "/swagger", info: {title: "Suma Admin API"}) if
      Suma::Service.swagger_enabled
  end

  SidekiqWeb = Rack::Builder.new do
    use Rack::Auth::Basic, "Protected Area" do |username, password|
      # Protect against timing attacks: (https://codahale.com/a-lesson-in-timing-attacks/)
      # - Use & (do not use &&) so that it doesn't short circuit.
      # - Use digests to stop length information leaking
      Rack::Utils.secure_compare(
        ::Digest::SHA256.hexdigest(username),
        ::Digest::SHA256.hexdigest(Suma::Async.web_username),
      ) & Rack::Utils.secure_compare(
        ::Digest::SHA256.hexdigest(password),
        ::Digest::SHA256.hexdigest(Suma::Async.web_password),
      )
    end
    use Rack::Session::Cookie, secret: Suma::Service.session_secret, same_site: true, max_age: 86_400
    run Sidekiq::Web
  end

  UrlRedirects = Rack::Builder.new do
    shortener = Suma::UrlShortener.new_shortener
    run ::UrlShortener::RackApp.new(shortener)
  end

  def self.emplace_dynamic_config
    dw = Rack::DynamicConfigWriter.new(
      "build-webapp/index.html",
      global_assign: "window.sumaDynamicEnv",
    )
    vars = self._dynamic_config_common_vars
    env = {
      "VITE_API_HOST" => vars[:api_host],
      "VITE_SENTRY_DSN" => Suma::Sentry.dsn,
      "VITE_STRIPE_PUBLIC_KEY" => Suma::Stripe.public_key,
      "VITE_RELEASE" => "sumaweb@" + vars[:release_version],
      "NODE_ENV" => vars[:node_env],
    }.merge(Rack::DynamicConfigWriter.pick_env("VITE_"))
    return dw.emplace(env)
  end

  def self.emplace_dynamic_config_adminapp
    dw = Rack::DynamicConfigWriter.new(
      "build-adminapp/index.html",
      global_assign: "window.sumaDynamicEnv",
    )
    vars = self._dynamic_config_common_vars
    env = {
      "VITE_API_HOST" => vars[:api_host],
      "VITE_RELEASE" => "sumaadmin@" + vars[:release_version],
      "NODE_ENV" => vars[:node_env],
    }.merge(Rack::DynamicConfigWriter.pick_env("VITE_"))
    return dw.emplace(env)
  end

  def self._dynamic_config_common_vars
    return {
      release_version: Suma::RELEASE.include?("unknown") ? Suma::VERSION : Suma::RELEASE,
      api_host: "/",
      node_env: "production",
    }
  end

  WEB_MOUNT_PATH = "/app"
  SECURITY_HEADERS = {
    "X-Frame-Options" => "DENY",
    "X-Content-Type-Options" => "nosniff",
    "Referrer-Policy" => "strict-origin-when-cross-origin",
    # A new policy can be generated at https://www.permissionspolicy.com/
    # Use all Standardized Features for 'self', along with whatever experimental features seem useful
    # to prohibit any cross-origin resources from accessing.
    # rubocop:disable Layout/LineLength
    "Permissions-Policy" => "accelerometer=(self), ambient-light-sensor=(self), autoplay=(self), battery=(self), camera=(self), cross-origin-isolated=(self), display-capture=(self), document-domain=(self), encrypted-media=(self), execution-while-not-rendered=(self), execution-while-out-of-viewport=(self), fullscreen=(self), geolocation=(self), gyroscope=(self), keyboard-map=(self), magnetometer=(self), microphone=(self), midi=(self), navigation-override=(self), payment=(self), picture-in-picture=(self), publickey-credentials-get=(self), screen-wake-lock=(self), sync-xhr=(self), usb=(self), web-share=(self), xr-spatial-tracking=(self), clipboard-read=(self), clipboard-write=(self)",
    # rubocop:enable Layout/LineLength
  }.freeze

  Web = Rack::Builder.new do
    script = Suma::Apps.emplace_dynamic_config
    self.use(
      Rack::Csp,
      policy: {
        safe: ["'self' mysuma.org *.mysuma.org", Suma::Sentry.dsn_host],
        inline_scripts: [script],
        script_hashes: Rack::Csp.extract_script_hashes(File.read("build-webapp/index.html")),
        parts: {
          "img-src" => "'self' mysuma.org *.mysuma.org data: api.mapbox.com",
          "connect-src" => "<SAFE> api.stripe.com",
          "frame-ancestors" => "'none'",
        },
      },
    )
    self.use(Rack::SimpleHeaders, SECURITY_HEADERS)
    Rack::SpaApp.run_spa_app(
      self,
      "build-webapp",
      enforce_ssl: Suma::Service.enforce_ssl,
      service_worker_allowed: WEB_MOUNT_PATH,
    )
  end

  Admin = Rack::Builder.new do
    script = Suma::Apps.emplace_dynamic_config_adminapp
    self.use(
      Rack::Csp,
      policy: {
        safe: ["'self' mysuma.org *.mysuma.org", Suma::Sentry.dsn_host],
        inline_scripts: [script],
        script_hashes: Rack::Csp.extract_script_hashes(File.read("build-adminapp/index.html")),
        img_data: true,
        img_blob: true,
        parts: {
          "style-src-elem" => "<SAFE> fonts.googleapis.com 'unsafe-inline'",
          "font-src" => "<SAFE> fonts.gstatic.com",
          "frame-ancestors" => "'none'",
        },
      },
    )
    self.use(Rack::SimpleHeaders, SECURITY_HEADERS)
    Rack::SpaApp.run_spa_app(self, "build-adminapp", enforce_ssl: Suma::Service.enforce_ssl)
  end

  Root = Rack::Builder.new do
    use(Rack::SslEnforcer, redirect_html: false) if Suma::Service.enforce_ssl
    use Rack::SimpleRedirect, routes: {/.*/ => ->(env) { "/app#{env['REQUEST_PATH']}" }}, status: 302
    run Rack::LambdaApp.new(->(_) { raise "Should not see this" })
  end
end
