# frozen_string_literal: true

require "suma/apps"
require "suma/async"

Suma::Async.setup_web

map "/api" do
  run Suma::Apps::API.build_app
end
map "/adminapi" do
  run Suma::Apps::AdminAPI.build_app
end
map Suma::Apps::WEB_MOUNT_PATH do
  run Suma::Apps::Web.to_app
end
map "/admin" do
  run Suma::Apps::Admin.to_app
end
map "/sidekiq" do
  run Suma::Apps::SidekiqWeb.to_app
end
map "/events" do
  run Suma::Apps::Events.to_app
end
map Suma::UrlShortener::ROOT_PATH do
  run Suma::Apps::UrlRedirects.to_app
end
run Suma::Apps::Root.to_app
