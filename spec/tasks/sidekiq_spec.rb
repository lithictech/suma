# frozen_string_literal: true

require "suma/spec_helpers/rake"
require "suma/tasks/sidekiq"

RSpec.describe Suma::Tasks::Sidekiq, sidekiq: :disable do
  include Suma::SpecHelpers::Rake

  describe "reset" do
    it "clears the redis DB" do
      Sidekiq.redis { |c| c.set("testkey", "1") }
      expect(Sidekiq.redis { |c| c.get("testkey") }).to eq("1")
      invoke_rake_task("sidekiq:reset")
      expect(Sidekiq.redis { |c| c.get("testkey") }).to be_nil
    end
  end

  describe "retry_all" do
    it "enqueues all retry set jobs for retry" do
      # Tested for coverage, sorry.
      invoke_rake_task("sidekiq:retry_all")
      expect(Sidekiq::RetrySet.new.size).to eq(0)
    end
  end

  describe "retry_all_dead" do
    it "enqueues all dead set jobs for retry" do
      # Tested for coverage, sorry.
      invoke_rake_task("sidekiq:retry_all_dead")
      expect(Sidekiq::DeadSet.new.size).to eq(0)
    end
  end
end
