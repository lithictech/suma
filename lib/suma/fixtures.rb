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
    def extended(mod)
      mod.define_singleton_method :fixtured_class do |cls=nil|
        # Must be defined like this to work with the DSL mixin, it's a weird implementation.
        (Suma::Fixtures.fixtured_class_to_fixture_module[cls] = self) if cls
        super(cls)
      end
      super
    end

    def fixtured_class_to_fixture_module = @fixtured_class_to_fixture_module ||= {}
    def fixtured_classes = self.fixtured_class_to_fixture_module.keys
    def fixture_modules = self.fixtured_class_to_fixture_module.values
    def fixture_module_for(cls) = self.fixtured_class_to_fixture_module.fetch(cls)

    def nilor(x, val)
      return val if x.nil?
      return x
    end
  end

  # Return the base factory, like Suma::Fixtures.member.
  def base_factory = Suma::Fixtures.send(self.base_fixture)

  # Implement/override this when the #base_factory cannot be created directly,
  # and other decorators are required to fixture the instance.
  def ensure_fixturable(factory) = factory
end
