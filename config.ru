# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "suma"
Suma.load_app

require "suma/apps"

Amigo.install_amigo_jobs
map "/api" do
  run Suma::Apps::API.build_app
end
map "/app" do
  run Suma::Apps::Web.to_app
end
run Suma::Apps::Root.to_app
