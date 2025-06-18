# frozen_string_literal: true

require "suma/sse"
require "suma/sse/middleware"

RSpec.describe Suma::SSE do
  it "can publish and subscribe through Redis" do
    got = nil
    t = Thread.new do
      described_class.subscribe("test") do |payload|
        got = payload
        break
      end
    end
    sleep(1) # Wait for the subscriber to set up
    described_class.publish("test", {x: 1})
    t.join
    expect(got).to include("payload" => {"x" => 1})
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
        Content-Type: text/event-stream
        Cache-Control: no-cache
        Connection: keep-alive
        Access-Control-Allow-Origin: *
      HTTP
      expect(sock.written).to include(": keep-alive\n\n")
      expect(sock.written).to include('data: {"payload":{"x":1},')
      expect(sock.closed).to be(true)
    end

    it "closes the socket if Redis errors" do
      expect(Suma::SSE).to receive(:subscribe).and_raise(Redis::CannotConnectError)
      expect(app.call(env).first).to eq(-1)
      sleep(1) # Wait for thread to set up
      expect(sock.closed).to be(true)
    end
  end
end
