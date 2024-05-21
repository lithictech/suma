# frozen_string_literal: true

require "amigo"
require "grape-swagger"
require "rack/builder"
require "rack/csp"
require "rack/dynamic_config_writer"
require "rack/lambda_app"
require "rack/service_worker_allowed"
require "rack/simple_redirect"
require "rack/spa_app"
require "rack/spa_rewrite"
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
require "suma/api/system"
require "suma/api/webhookdb"

require "suma/admin_api/auth"
require "suma/admin_api/bank_accounts"
require "suma/admin_api/book_transactions"
require "suma/admin_api/commerce_offerings"
require "suma/admin_api/commerce_orders"
require "suma/admin_api/commerce_products"
require "suma/admin_api/commerce_offering_products"
require "suma/admin_api/eligibility_constraints"
require "suma/admin_api/funding_transactions"
require "suma/admin_api/members"
require "suma/admin_api/message_deliveries"
require "suma/admin_api/meta"
require "suma/admin_api/organizations"
require "suma/admin_api/organization_memberships"
require "suma/admin_api/payment_ledgers"
require "suma/admin_api/payment_triggers"
require "suma/admin_api/payout_transactions"
require "suma/admin_api/roles"
require "suma/admin_api/search"
require "suma/admin_api/vendors"
require "suma/admin_api/anon_proxy"

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
    mount Suma::API::Webhookdb
    add_swagger_documentation(mount_path: "/swagger", info: {title: "Suma App API"}) if
      Suma::Service.swagger_enabled
  end

  class AdminAPI < Suma::Service
    mount Suma::AdminAPI::AnonProxy
    mount Suma::AdminAPI::Auth
    mount Suma::AdminAPI::BankAccounts
    mount Suma::AdminAPI::BookTransactions
    mount Suma::AdminAPI::CommerceOfferings
    mount Suma::AdminAPI::CommerceOrders
    mount Suma::AdminAPI::CommerceProducts
    mount Suma::AdminAPI::CommerceOfferingProducts
    mount Suma::AdminAPI::EligibilityConstraints
    mount Suma::AdminAPI::FundingTransactions
    mount Suma::AdminAPI::Members
    mount Suma::AdminAPI::MessageDeliveries
    mount Suma::AdminAPI::Meta
    mount Suma::AdminAPI::Organizations
    mount Suma::AdminAPI::OrganizationMemberships
    mount Suma::AdminAPI::PaymentLedgers
    mount Suma::AdminAPI::PaymentTriggers
    mount Suma::AdminAPI::PayoutTransactions
    mount Suma::AdminAPI::Roles
    mount Suma::AdminAPI::Search
    mount Suma::AdminAPI::Vendors
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
    dw.emplace(env)
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
    dw.emplace(env)
  end

  def self._dynamic_config_common_vars
    return {
      release_version: Suma::RELEASE.include?("unknown") ? Suma::VERSION : Suma::RELEASE,
      api_host: "/",
      node_env: "production",
    }
  end

  WEB_MOUNT_PATH = "/app"

  Web = Rack::Builder.new do
    Suma::Apps.emplace_dynamic_config
    # self.use Rack::Csp, policy: "default-src 'self' mysuma.org *.mysuma.org; img-src 'self' data:"
    Rack::SpaApp.run_spa_app(
      self,
      "build-webapp",
      enforce_ssl: Suma::Service.enforce_ssl,
      service_worker_allowed: WEB_MOUNT_PATH,
    )
  end

  Admin = Rack::Builder.new do
    Suma::Apps.emplace_dynamic_config_adminapp
    # self.use Rack::Csp, policy: "default-src 'self'; img-src 'self' data:"
    Rack::SpaApp.run_spa_app(self, "build-adminapp", enforce_ssl: Suma::Service.enforce_ssl)
  end

  Root = Rack::Builder.new do
    use(Rack::SslEnforcer, redirect_html: false) if Suma::Service.enforce_ssl
    use Rack::SimpleRedirect, routes: {/.*/ => ->(env) { "/app#{env['REQUEST_PATH']}" }}, status: 302
    run Rack::LambdaApp.new(->(_) { raise "Should not see this" })
  end
end
