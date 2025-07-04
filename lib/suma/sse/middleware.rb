# frozen_string_literal: true

require "puma/const"
require "puma/null_io"
require "puma/client"
require "suma/sse"
require "suma/sse/auth"

class Suma::SSE::Middleware
  include Appydays::Loggable

  HEADERS = {
    Rack::CONTENT_TYPE => "text/event-stream",
    Rack::CACHE_CONTROL => "no-cache",
    "connection" => "keep-alive",
    "access-control-allow-origin" => "*", # This is fine for our purposes
  }.freeze

  class << self
    # This is shared between all event middleware.
    attr_accessor :keepalive

    # Return the client collection for the process.
    # We use a global collection of clients,
    # with a single keepalive thread, to save on resources.
    def clients = @clients ||= ClientCollection.new

    def reset_clients
      @clients&.pinger&.kill
      @clients = nil
      self.keepalive = 25.seconds
    end
  end

  def initialize(app, topic:, path: "/#{topic}")
    @app = app
    @topic = topic
    @path = path
  end

  def call(env)
    return @app.call unless env["PATH_INFO"] == @path

    token = Rack::Request.new(env).GET["token"]
    return [401, {Rack::CONTENT_TYPE => "text/plain"}, "Unauthorized"] unless
      Suma::SSE::Auth.validate_token(token)

    # We must use the socket directly so we disconnect as soon as a write fails.
    # Otherwise, Rack may buffer writes for a long time, even after the client has disconnected.
    # This causes the thread to hang, which is super expensive.
    env["rack.hijack"].call
    socket = env["rack.hijack_io"]
    client = self.class.clients.add_client(@path, socket)
    Thread.new do
      Suma::SSE.subscribe(@topic, session_id: token) do |msg|
        break unless self.class.clients.senddata(client, msg.to_json)
      end
    rescue StandardError => e
      Suma::SSE::Middleware.clients.logger.warn("subscriber_error", {client_id: client.id}, e)
    ensure
      self.class.clients.disconnect!(client, nil)
    end
    socket.write "HTTP/1.1 200 OK\r\n"
    HEADERS.each do |k, v|
      socket.write "#{k}: #{v}\r\n"
    end
    socket.write "\r\n"
    socket.flush
    [-1, {}, []]
  end

  class ClientCollection
    attr_reader :pinger, :logger

    def initialize
      @clients = []
      @counter = 0
      @logger = Suma::SSE.logger
      @pinger = Thread.new(name: "sse-middleware") do
        # Use one thread to perform keepalives on all connected clients.
        # This prevents each SSE request from using three threads;
        # instead it can just one additional thread, plus the handler thread.
        loop do
          sleep(Suma::SSE::Middleware.keepalive)
          @clients.to_a.each do |client|
            @logger.debug "eventsource_keepalive", client_id: client.id
            self.keepalive(client)
          end
        end
      end
      # We don't need to know about exceptions, we kill this thread forcefully.
      @pinger.report_on_exception = false
    end

    def add_client(path, socket)
      @counter += 1
      client = Client.new("#{@counter}-#{SecureRandom.hex(2)}", socket)
      @clients << client
      @logger.info("eventsource_connected", client_id: client.id, client_count: @clients.count, path:)
      return client
    end

    def senddata(client, data)
      @logger.debug "eventsource_data", client_id: client.id
      return self.send!(client, "data: #{data}")
    end

    def keepalive(client) = send!(client, ": keep-alive")

    protected def send!(client, msg)
      client << "#{msg}\n\n"
      return true
    rescue Puma::ConnectionError, IOError, Errno::EPIPE => e
      self.disconnect!(client, e)
      return false
    end

    def disconnect!(client, ex)
      # Allow disconnect! to be called multiple times
      return unless @clients.delete(client)
      client.disconnect
      @logger.debug "eventsource_disconnected", client_id: client.id, exception_class: ex&.class&.name
    end
  end

  class Client
    attr_reader :id

    def initialize(id, socket)
      @id = id
      @socket = socket
      @mux = Thread::Mutex.new
    end

    def <<(msg)
      @mux.synchronize do
        @socket.write(msg)
        @socket.flush
      end
      sleep(0.5) # Return control back to Puma, etc.m
    end

    def disconnect
      @socket.close
    end
  end
end

Suma::SSE::Middleware.reset_clients
