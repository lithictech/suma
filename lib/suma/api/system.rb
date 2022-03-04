# frozen_string_literal: true

require "grape"

require "suma/api"
require "suma/postgres"

# Health check and other metadata endpoints.
class Suma::API::System < Suma::Service
  format :json

  require "suma/service/helpers"
  helpers Suma::Service::Helpers

  get :healthz do
    Suma::Postgres::Model.db.execute("SELECT 1=1")
    status 200
    {o: "k"}
  end

  get :statusz do
    status 200
    {
      env: Suma::RACK_ENV,
      version: Suma::VERSION,
      release: Suma::RELEASE,
      log_level: Suma.logger.level,
    }
  end
end
