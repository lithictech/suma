# frozen_string_literal: true

require "faker"
require "fluent_fixtures"

require "suma"

module Suma::Fixtures
  extend FluentFixtures::Collection

  # Set the path to use when finding fixtures for this collection
  fixture_path_prefix "suma/fixtures"

  ::Faker::Config.locale = :en

  class << self
    def nilor(x, val)
      return val if x.nil?
      return x
    end
  end
end
