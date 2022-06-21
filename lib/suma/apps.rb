# frozen_string_literal: true

require "amigo"
require "grape-swagger"
require "rack/builder"
require "rack/lambda_app"
require "rack/simple_redirect"
require "rack/spa_app"
require "rack/spa_rewrite"

require "suma/api"
require "suma/async"
require "suma/service"
require "suma/api/auth"
require "suma/api/ledgers"
require "suma/api/me"
require "suma/api/meta"
require "suma/api/mobility"
require "suma/api/payment_instruments"
require "suma/api/payments"
require "suma/api/system"

require "suma/admin_api/auth"
require "suma/admin_api/bank_accounts"
require "suma/admin_api/members"
require "suma/admin_api/message_deliveries"
require "suma/admin_api/roles"

module Suma::Apps
  class API < Suma::Service
    mount Suma::API::System
    mount Suma::API::Auth
    mount Suma::API::Ledgers
    mount Suma::API::Me
    mount Suma::API::Meta
    mount Suma::API::Mobility
    mount Suma::API::PaymentInstruments
    mount Suma::API::Payments
    add_swagger_documentation if ENV["RACK_ENV"] == "development"
  end

  class AdminAPI < Suma::Service
    mount Suma::AdminAPI::Auth
    mount Suma::AdminAPI::BankAccounts
    mount Suma::AdminAPI::Members
    mount Suma::AdminAPI::MessageDeliveries
    mount Suma::AdminAPI::Roles
    add_swagger_documentation if ENV["RACK_ENV"] == "development"
  end

  Web = Rack::Builder.new do
    Rack::SpaApp.run_spa_app(self, "build-webapp", enforce_ssl: Suma::Service.enforce_ssl)
  end

  Admin = Rack::Builder.new do
    Rack::SpaApp.run_spa_app(self, "build-adminapp", enforce_ssl: Suma::Service.enforce_ssl)
  end

  Root = Rack::Builder.new do
    use(Rack::SslEnforcer, redirect_html: false) if Suma::Service.enforce_ssl
    use Rack::SimpleRedirect, routes: {/.*/ => ->(env) { "/app#{env['REQUEST_PATH']}" }}, status: 302
    run Rack::LambdaApp.new(->(_) { raise "Should not see this" })
  end
end
