# frozen_string_literal: true

require "amigo"
require "grape-swagger"
require "rack/builder"
require "rack/lambda_app"
require "rack/simple_redirect"
require "rack/spa_rewrite"

require "suma/api"
require "suma/async"
require "suma/service"
require "suma/api/auth"
require "suma/api/me"
require "suma/api/meta"
require "suma/api/mobility"
require "suma/api/system"

require "suma/admin_api/auth"
require "suma/admin_api/customers"
require "suma/admin_api/message_deliveries"
require "suma/admin_api/roles"

module Suma::Apps
  class API < Suma::Service
    mount Suma::API::System
    mount Suma::API::Auth
    mount Suma::API::Me
    mount Suma::API::Meta
    mount Suma::API::Mobility
    add_swagger_documentation if ENV["RACK_ENV"] == "development"
  end

  class AdminAPI < Suma::Service
    mount Suma::AdminAPI::Auth
    mount Suma::AdminAPI::Customers
    mount Suma::AdminAPI::MessageDeliveries
    mount Suma::AdminAPI::Roles
    add_swagger_documentation if ENV["RACK_ENV"] == "development"
  end

  Web = Rack::Builder.new do
    use Rack::SpaRewrite, index_path: "build-webapp/index.html", html_only: true
    use Rack::Static, urls: [""], root: "build-webapp", cascade: true
    use Rack::SpaRewrite, index_path: "build-webapp/index.html", html_only: false
    run Rack::LambdaApp.new(->(_) { raise "Should not see this" })
  end

  Admin = Rack::Builder.new do
    use Rack::SpaRewrite, index_path: "build-adminapp/index.html", html_only: true
    use Rack::Static, urls: [""], root: "build-adminapp", cascade: true
    use Rack::SpaRewrite, index_path: "build-adminapp/index.html", html_only: false
    run Rack::LambdaApp.new(->(_) { raise "Should not see this" })
  end

  Root = Rack::Builder.new do
    use Rack::SimpleRedirect, routes: {/.*/ => ->(env) { "/app#{env['REQUEST_PATH']}" }}, status: 302
    run Rack::LambdaApp.new(->(_) { raise "Should not see this" })
  end
end
