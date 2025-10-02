# frozen_string_literal: true

require "suma/autoscaler"

RSpec.describe Suma::Autoscaler, reset_configuration: [Suma::Autoscaler, Suma::Heroku] do
  describe "build_worker" do
    it "conditionally adds handlers" do
      Suma::Heroku.oauth_token = "x"
      described_class.worker_handlers = "heroku+sentry"
      as = described_class.build_worker
      expect(as.handler.chain).to contain_exactly(
        be_a(Amigo::Autoscaler::Handlers::Log),
        be_a(Amigo::Autoscaler::Handlers::Heroku),
        be_a(Amigo::Autoscaler::Handlers::Sentry),
      )

      described_class.worker_handlers = "heroku"
      as = described_class.build_worker
      expect(as.handler.chain).to contain_exactly(
        be_a(Amigo::Autoscaler::Handlers::Log),
        be_a(Amigo::Autoscaler::Handlers::Heroku),
      )

      described_class.worker_handlers = "sentry"
      as = described_class.build_worker
      expect(as.handler.chain).to contain_exactly(
        be_a(Amigo::Autoscaler::Handlers::Log),
        be_a(Amigo::Autoscaler::Handlers::Sentry),
      )

      described_class.worker_handlers = ""
      as = described_class.build_worker
      expect(as.handler.chain).to contain_exactly(
        be_a(Amigo::Autoscaler::Handlers::Log),
      )
    end

    it "uses a logging handler" do
      described_class.worker_handlers = ""
      as = described_class.build_worker
      logs = capture_logs_from(described_class.logger) do
        as.handler.scale_up(high_latencies: {}, duration: 1.0, depth: 1, pool_usage: 1.1)
      end
      expect(logs).to have_a_line_matching(/high_latency_queues/)
    end

    it "captures unhandled exceptions" do
      as = described_class.build_worker
      e = RuntimeError.new("hi")
      expect(Sentry).to receive(:capture_exception).with(e)
      as.on_unhandled_exception.call(e)
    end
  end

  describe "build_web" do
    it "runs" do
      described_class.web_handlers = "sentry"
      as = described_class.build_web
      expect(as.handler.chain).to contain_exactly(
        be_a(Amigo::Autoscaler::Handlers::Log),
        be_a(Amigo::Autoscaler::Handlers::Sentry),
      )
    end
  end
end
