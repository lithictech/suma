# frozen_string_literal: true

require "suma/async"
require "suma/rack_attack"

RSpec.describe Suma::RackAttack, :db do
  describe "configuration", reset_configuration: described_class do
    it "does not enable RA if not enabled" do
      described_class.reset_configuration(enabled: false)
      expect(Rack::Attack).to have_attributes(enabled: false)
      expect(Rack::Attack.cache.store).to be_nil
    end

    it "sets RA to enabled with a memory store if Redis urls are not set" do
      described_class.reset_configuration(enabled: true)
      expect(Rack::Attack).to have_attributes(enabled: true)
      expect(Rack::Attack.cache.store).to be_a(ActiveSupport::Cache::MemoryStore)
    end

    it "can set the redis store from the url" do
      described_class.reset_configuration(enabled: true, redis_url: Suma::Async.sidekiq_redis_url)
      expect(Rack::Attack).to have_attributes(enabled: true)
      expect(Rack::Attack.cache.store).to respond_to(:redis)
    end

    it "can set the redis store from the provider" do
      ENV["TEMP_REDIS_URL"] = Suma::Async.sidekiq_redis_url
      described_class.reset_configuration(enabled: true, redis_provider: "TEMP_REDIS_URL")
      expect(Rack::Attack).to have_attributes(enabled: true)
      expect(Rack::Attack.cache.store).to respond_to(:redis)
    ensure
      ENV.delete("TEMP_REDIS_URL")
    end
  end
end
