# frozen_string_literal: true

require "suma/sse"
require "suma/sse/middleware"

RSpec.describe Suma::SSE do
  describe "pubsub" do
    it "includes the current session id, including the current session" do
      got = []
      t = Thread.new do
        described_class.subscribe("test") do |message|
          got << message
        end
      end

      # Keep publishing because we have to wait for the subscriber to be set up.
      until got.any?
        described_class.publish("test", {x: 1})
        sleep(0.01)
      end
      expect(got.first).to include("payload" => {"x" => 1})

      # Once the subscriber is set up, we can test on a single publish.
      begin
        described_class.current_session_id = "abc"
        described_class.publish("test", {x: 2})
      ensure
        described_class.current_session_id = nil
      end
      expect { got.last }.to eventually(include("payload" => {"x" => 2}, "sid" => "abc"))
    ensure
      t.kill
    end

    it "skips events published by the subscriber session" do
      sessid = "session1"
      got = []
      t = Thread.new do
        described_class.subscribe("test", session_id: sessid) do |message|
          got << message
        end
      end

      until got.any?
        described_class.publish("test", {x: 1})
        sleep(0.01)
      end
      expect(got.first).to include("payload" => {"x" => 1})

      begin
        # This event is skipped since it's from our session
        described_class.current_session_id = sessid
        described_class.publish("test", {x: 3})
        # This event is recorded since it's from another session
        described_class.current_session_id = "eventfromother"
        described_class.publish("test", {x: 2})
      ensure
        described_class.current_session_id = nil
      end
      expect { got.last }.to eventually(include("payload" => {"x" => 2}, "sid" => "eventfromother"))
    ensure
      t.kill
    end

    erroring_redis = Class.new do
      attr_reader :pubsub, :calls

      def initialize(ex)
        @ex = ex
        @calls = []
      end

      def pubsub = self

      def call(*cmd)
        @calls << cmd
        raise @ex
      end
    end

    it "reports and ignores on connection errors (unless publish! is used)", reset_configuration: described_class do
      ex = RedisClient::ConnectionError.new
      redis = erroring_redis.new(ex)
      described_class.publisher_redis = redis
      expect { described_class.publish!("test", {}) }.to raise_error(ex)
      expect(Sentry).to receive(:capture_exception).with(ex)
      expect { described_class.publish("test", {}) }.to_not raise_error
    end
  end

  describe described_class::Auth do
    it "can generate and validate tokens" do
      tok = described_class.generate_token
      expect(described_class.validate_token(tok)).to be(true)
      tok = described_class.generate_token(now: 3.minutes.ago)
      expect(described_class.validate_token(tok)).to be(true)
      tok = described_class.generate_token(now: 1.hour.ago)
      expect(described_class.validate_token(tok)).to be(false)
      expect(described_class.validate_token(nil)).to be(false)
    end

    it "can raise specific errors" do
      expect { described_class.validate_token!("abc") }.to raise_error(described_class::Malformed)
      tok = described_class.generate_token(now: 1.hour.ago)
      expect { described_class.validate_token!(tok) }.to raise_error(described_class::Expired)
      expect { described_class.validate_token!(nil) }.to raise_error(described_class::Missing)
    end

    it "removes padding from the token" do
      Array.new(100) do
        tok = described_class.generate_token
        expect(tok).to_not include("=")
        expect(tok).to_not include("%")
      end
    end
  end

  describe described_class::Middleware do
    let(:app) { described_class.new(Suma::SSE::NotFound.new, topic: "test") }
    let(:sock) { fake_socket_cls.new }
    let(:env) do
      {
        "PATH_INFO" => "/test",
        "QUERY_STRING" => "token=#{Suma::SSE::Auth.generate_token}",
        "rack.hijack" => proc {},
        "rack.hijack_io" => sock,
      }
    end
    let(:fake_socket_cls) do
      Class.new do
        attr_accessor :written, :flushes, :closed, :broken

        def write(s)
          @written ||= +""
          @written << s
        end

        def flush
          @flushes ||= 0
          @flushes += 1
          raise EOFError if self.broken
        end

        def close
          @closed = true
        end
      end
    end

    before(:each) do
      Suma::SSE::Middleware.reset_clients
    end

    after(:each) do
      Suma::SSE::Middleware.reset_clients
    end

    it "only runs for a matching path" do
      env["PATH_INFO"] = "/others"
      expect(app.call(env).first).to eq(404)
    end

    it "401s if unauthed" do
      env["QUERY_STRING"] = "token=#{Suma::SSE::Auth.generate_token(now: 20.minutes.ago)}"
      expect(app.call(env).first).to eq(401)
    end

    it "responds with serverside events" do
      Suma::SSE::Middleware.keepalive = 0.1
      expect(app.call(env).first).to eq(-1)
      sleep(1) # Wait for thread to set up
      Suma::SSE.publish("test", {x: 1})
      sock.broken = true
      sleep(1)
      expect(sock.flushes).to be_positive
      expect(sock.written.gsub("\r\n", "\n")).to start_with(<<~HTTP)
        HTTP/1.1 200 OK
        content-type: text/event-stream
        cache-control: no-cache
        connection: keep-alive
        access-control-allow-origin: *
      HTTP
      expect(sock.written).to include(": keep-alive\n\n")
      expect(sock.written).to include('data: {"payload":{"x":1},')
      expect(sock.closed).to be(true)
    end

    it "closes the socket if Redis errors" do
      expect(Suma::SSE).to receive(:subscribe).and_raise(RedisClient::CannotConnectError)
      expect(app.call(env).first).to eq(-1)
      sleep(1) # Wait for thread to set up
      expect(sock.closed).to be(true)
    end
  end
end
