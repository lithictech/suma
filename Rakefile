# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "appydays/dotenviable"
Appydays::Dotenviable.load

require "sentry-ruby"

require "suma/tasks/annotate"
Suma::Tasks::Annotate.new
require "suma/tasks/db"
Suma::Tasks::DB.new
require "suma/tasks/bootstrap"
Suma::Tasks::Bootstrap.new
require "suma/tasks/frontend"
Suma::Tasks::Frontend.new
require "suma/tasks/heroku"
Suma::Tasks::Heroku.new
require "suma/tasks/i18n"
Suma::Tasks::I18n.new
require "suma/tasks/release"
Suma::Tasks::Release.new
require "suma/tasks/message"
Suma::Tasks::Message.new
require "suma/tasks/sidekiq"
Suma::Tasks::Sidekiq.new
