# frozen_string_literal: true

# See https://github.com/eliotsykes/rspec-rails-examples/blob/master/spec/spec_helper.rb
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
#
require "appydays/dotenviable"
Appydays::Dotenviable.load(default_rack_env: "test")

require "simplecov"
require "simplecov-cobertura"

(SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter) if ENV["CI"]
SimpleCov.start if ENV["CI"] || ENV["COVERAGE"]

require "httparty"
require "rack/test"
require "rack/test/methods"
require "rspec"
require "rspec/json_expectations"
require "rspec/temp_dir"
require "timecop"
require "webmock/rspec"
require "appydays/spec_helpers"
require "appydays/configurable/spec_helpers"
require "appydays/loggable/spec_helpers"
require "amigo/spec_helpers"
require "state_machines/sequel/spec_helpers"

require "suma"
require "suma/fixtures"

Suma.load_app
Suma::Fixtures.load_all

RSpec.configure do |config|
  config.full_backtrace = true

  RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 600

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random
  Kernel.srand config.seed

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?

  config.include(Appydays::SpecHelpers)
  config.include(Appydays::Configurable::SpecHelpers)
  config.include(Appydays::Loggable::SpecHelpers)
  config.include(Amigo::SpecHelpers)

  if Suma::INTEGRATION_TESTS_ENABLED
    require "suma/spec_helpers/integration"
    config.include(Suma::SpecHelpers::Integration)
    require "suma/spec_helpers/postgres"
    config.include(Suma::SpecHelpers::Postgres)
  else
    require "sidekiq/testing"
    Sidekiq::Testing.inline!
    require "suma/spec_helpers"
    config.include(Suma::SpecHelpers)
    require "suma/spec_helpers/i18n"
    config.include(Suma::SpecHelpers::I18n)
    require "suma/spec_helpers/message"
    config.include(Suma::SpecHelpers::Message)
    require "suma/spec_helpers/postgres"
    config.include(Suma::SpecHelpers::Postgres)
    require "suma/spec_helpers/service"
    config.include(Suma::SpecHelpers::Service)
  end
end
