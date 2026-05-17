# frozen_string_literal: true

require "suma/performance"

RSpec.describe Suma::Performance, reset_configuration: Suma::Performance do
  logger_cls = Class.new do
    attr_accessor :calls

    def initialize
      self.calls = []
    end

    def info(event, kwargs={})
      self.calls << {event:, **kwargs}
    end
  end

  let(:logger) { logger_cls.new }
  def create_app
    described_class::RackMiddleware.new(lambda do |_env|
      yield
      [200, {}, ["OK"]]
    end, logger:,)
  end

  it "runs middleware that logs if enabled" do
    described_class.request_middleware = true
    app = create_app do
      described_class.log_sql("BEGIN", 0.001)
      described_class.log_sql("SELECT 1", 0.01)
      described_class.log_sql("SELECT 2", 0.1)
      described_class.log_sql("SELECT 1", 0.001)
      described_class.log_sql("BEGIN", 0.001)
    end
    app.call({})
    expect(logger.calls).to contain_exactly(
      include(event: :performance, sql_duration: 0.113, sql_exact_duplicates: 1, sql_queries: 3,
              sql_similar_duplicates: 2, sql_slow_queries: 1, sql_xactions: 2,),
      include(event: :duplicate_query, query: "SELECT 1", extra_calls: 1),
      include(event: :similar_query, query: "SELECT 1", homogenized_query: "SELECT 0", extra_calls: 1),
      include(event: :slow_query, query: "SELECT 2", duration: 0.1),
    )
  end

  it "noops if not enabled" do
    described_class.request_middleware = false

    app = create_app do
      described_class.log_sql("SELECT 1", 1)
    end
    app.call({})
    expect(logger.calls).to be_empty
  end

  it "does not log duplicate and slow queries if not enabled" do
    described_class.request_middleware = true
    described_class.log_duplicates = false
    described_class.log_slow = false

    app = create_app do
      described_class.log_sql("SELECT 1", 0.01)
      described_class.log_sql("SELECT 2", 0.1)
      described_class.log_sql("SELECT 1", 0.001)
    end
    app.call({})
    expect(logger.calls).to contain_exactly(
      include(event: :performance, sql_exact_duplicates: 1, sql_similar_duplicates: 2, sql_slow_queries: 1),
    )
  end

  it "overrides the Sequel database logger" do
    described_class.request_middleware = true

    app = create_app do
      Suma::Postgres::Model.db << "SELECT 1"
    end
    app.call({})
    expect(logger.calls).to contain_exactly(
      include(event: :performance, sql_queries: 1),
    )
  end

  describe "memory_kb" do
    describe "on Mac OS" do
      before(:each) do
        expect(Suma).to receive(:macos?).and_return(true)
      end

      it "returns kb from ps" do
        expect(Process).to receive(:pid).and_return(123)
        expect(Kernel).to receive(:`).with("ps -o rss= -p 123").and_return("456\n")
        expect(Suma::Performance.memory_kb).to eq(456)
      end

      it "returns 0 on an unexpected stdout" do
        expect(Process).to receive(:pid).and_return(123)
        expect(Kernel).to receive(:`).with("ps -o rss= -p 123").and_return("xyz\n")
        expect(Suma::Performance.memory_kb).to eq(0)
      end
    end

    describe "on Linux" do
      before(:each) do
        expect(Suma).to receive(:macos?).and_return(false)
      end

      it "returns the output of /proc/self/status" do
        expect(File).to receive(:foreach).with("/proc/self/status").and_wrap_original do |*, &b|
          b.call("Name:	ruby\n")
          b.call("VmHWM:	   15000 kB\n")
          b.call("VmRSS:	   14000 kB\n")
        end
        expect(Suma::Performance.memory_kb).to eq(14_000)
      end

      it "uses 0 if VmRSS not found" do
        expect(File).to receive(:foreach).with("/proc/self/status").and_wrap_original do |*, &b|
          b.call("Name:	ruby\n")
          b.call("VmHWM:	   15000 kB\n")
        end
        expect(Suma::Performance.memory_kb).to eq(0)
      end
    end
  end

  describe "vernier app" do
    include Rack::Test::Methods

    after(:each) do
      app.collector&.stop
      app.tempfile&.unlink
    end

    keyp = "?key=xy"

    let(:app) { Suma::Performance::VernierRackApp.new(key: "xy") }

    describe "with start=true" do
      it "can start a collector with the given values" do
        expect(app.collector).to be_nil
        expect(app.tempfile).to be_nil

        get "#{keyp}&start=true&mode=retained"

        expect(last_response).to have_status(200)
        expect(app.collector).to be_a(Vernier::Collector::RetainedCollector)
        expect(app.tempfile).to be_a(Tempfile)
      end

      it "starts a collector with default values" do
        get "#{keyp}&start=true"

        expect(last_response).to have_status(200)
        expect(app.collector).to be_a(Vernier::Collector::TimeCollector)
      end

      it "can stop and replace and existing collector" do
        get "#{keyp}&start=true"

        expect(last_response).to have_status(200)
        expect(app.collector).to be_a(Vernier::Collector::TimeCollector)

        get "#{keyp}&start=true&mode=retained"

        expect(last_response).to have_status(200)
        expect(app.collector).to be_a(Vernier::Collector::RetainedCollector)
      end
    end

    describe "with stop=true" do
      it "stops and reports the running collector" do
        get "#{keyp}&start=true"

        expect(last_response).to have_status(200)
        expect(app.collector).to be_a(Vernier::Collector)
        expect(app.tempfile).to be_present

        get "#{keyp}&stop=true"

        expect(last_response).to have_status(200)
        expect(app.collector).to be_nil
        expect(app.tempfile).to be_nil
        expect(last_response.headers).to include(
          "content-disposition",
          "content-length",
          "content-type" => "application/octet-stream",
        )
        expect(last_response.body).to include("\x1F")
      end

      it "errors if no collector is running" do
        get "#{keyp}&stop=true"

        expect(last_response).to have_status(400)
        expect(last_response.body).to include("collector not running")
      end
    end

    it "requires a valid key param" do
      get "?key=1&start=true"

      expect(last_response).to have_status(401)
    end
  end
end
