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

  describe "open_web" do
    it "opens a web browser" do
      expect(Kernel).to receive(:`)
      described_class.open_web
    end
  end

  describe "setup" do
    before(:all) do
      # Make sure this is called before tests run, since they mock Amigo, requiring jobs would error
      described_class.setup_tests
    end

    it "errors if called multiple times" do
      amigo = double("Amigo", structured_logging: true)
      stub_const("Amigo", amigo)
      expect(amigo).to receive(:structured_logging).and_return(true)
      expect { described_class.setup_web }.to raise_error(RuntimeError, /only call this once/)
    end

    describe "setup_web" do
      it "installs Amigo jobs" do
        amigo = double("Amigo",
                       :install_amigo_jobs => true,
                       structured_logging: false,
                       :structured_logging= => true,
                       :log_callback= => true,)
        stub_const("Amigo", amigo)
        expect(amigo).to receive(:install_amigo_jobs)
        expect(amigo).to receive(:structured_logging=)
        expect(amigo).to receive(:log_callback=)
        expect(described_class.setup_web).to be(true)
      end
    end

    describe "setup_workers" do
      it "installs Amigo jobs" do
        amigo = double("Amigo",
                       :install_amigo_jobs => true,
                       structured_logging: false,
                       :structured_logging= => true,
                       :log_callback= => true,
                       :start_scheduler= => true,)
        stub_const("Amigo", amigo)
        expect(amigo).to receive(:install_amigo_jobs)
        expect(amigo).to receive(:structured_logging=)
        expect(amigo).to receive(:log_callback=)
        expect(amigo).to receive(:start_scheduler)
        expect(described_class.setup_workers).to be(true)
      end
    end
  end

  describe "cron_job_options" do
    it "uses no args for the lock args method" do
      opts = described_class.cron_job_options
      expect(opts.fetch(:lock_args_method).call(nil)).to eq([])
    end
  end
end
