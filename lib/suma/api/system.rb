# frozen_string_literal: true

require "browser"
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

  get :useragent do
    status 200
    use_http_expires_caching 7.days
    browser = Browser.new(request.headers["User-Agent"], accept_language: "en-us")
    {
      # get the second word in case of "Microsoft Edge"
      browser: browser.name.downcase.split.last || browser.platform.name.downcase,
      # get the first word in case of "ios (device)"
      platform: browser.platform.name.downcase.split.first,
      is_apple: browser.platform.ios? || browser.platform.mac? || browser.safari?,
      supported_platform: browser.platform.windows? || browser.platform.android? || browser.platform.ios? ||
        browser.platform.mac?,
      supported_browser: browser.chrome? || browser.firefox? || browser.edge?,
    }
  end
end
