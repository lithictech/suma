# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "suma"
Suma.load_app

require "amigo"
require "grape"
require "grape_logging"
require "grape-swagger"
require "rack/cors"
require "rack/lint"

require "suma/api"
require "suma/async"
require "suma/service"

require "suma/api/auth"
require "suma/api/me"
require "suma/api/system"

require "suma/admin_api/auth"
require "suma/admin_api/customers"
require "suma/admin_api/message_deliveries"
require "suma/admin_api/roles"

class Suma::App < Suma::Service
  mount Suma::API::System
  mount Suma::API::Auth
  mount Suma::API::Me

  mount Suma::AdminAPI::Auth
  mount Suma::AdminAPI::Customers
  mount Suma::AdminAPI::MessageDeliveries
  mount Suma::AdminAPI::Roles

  add_swagger_documentation if ENV["RACK_ENV"] == "development"
end

Amigo.install_amigo_jobs
run Suma::App.build_app
