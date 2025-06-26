# frozen_string_literal: true

require "suma/async/autoscaler"

RSpec.describe Suma::Async do
  describe "Autoscaler" do
    it "starts an autoscaler" do
      Suma::Async::Autoscaler.start
      Suma::Async::Autoscaler.instance.stop
    end
  end

  describe "JobLogger" do
    it "returns configured slow seconds" do
      expect(Suma::Async::JobLogger.new(Sidekiq::Config.new).method(:slow_job_seconds).call).to eq(1)
    end
  end

  describe "configuration" do
    it "can configure the Sidekiq server" do
      cfg = Sidekiq::Config.new
      described_class.configure_sidekiq_server(cfg)
      expect(cfg.error_handlers).to have_length(2)
      expect(cfg.death_handlers).to have_length(2)
      expect(cfg[:job_logger]).to eq(Suma::Async::JobLogger)
      expect(cfg.instance_variable_get(:@redis_config)).to eq({url: "redis://localhost:22007/0"})
    end

    it "can configure the Sidekiq client" do
      cfg = Sidekiq::Config.new
      described_class.configure_sidekiq_client(cfg)
      expect(cfg.instance_variable_get(:@redis_config)).to eq({url: "redis://localhost:22007/0"})
    end
  end
end
