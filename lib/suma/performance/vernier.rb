# frozen_string_literal: true

module Suma::Performance::Vernier
  DEFAULT_MODE = :wall
  DEFAULT_INTERVAL = 100
  DEFAULT_ALLOCATION_INTERVAL = 10
  DEFAULT_MEMORY_USAGE = true

  def parse_params(h, mode: nil, interval: nil, allocation_interval: nil, memory_usage: nil, prefix: "")
    memory_usage = h["#{prefix}memory_usage"] if memory_usage.nil?
    memory_usage = DEFAULT_MEMORY_USAGE if memory_usage.nil?
    mode = (h["#{prefix}mode"] || mode || DEFAULT_MODE).to_sym
    interval = h["#{prefix}interval"] || interval || DEFAULT_INTERVAL
    allocation_interval = h["#{prefix}allocation_interval"] || allocation_interval || DEFAULT_ALLOCATION_INTERVAL

    hooks = [:activesupport]
    hooks << :memory_usage if memory_usage

    opts = {mode:, hooks:}
    if mode == :wall
      opts[:interval] = interval.to_i
      opts[:allocation_interval] = allocation_interval.to_i
    end
    return opts
  end

  def checkauth(k1, k2)
    return unauth("invalid key") unless k1 && k2 && Rack::Utils.secure_compare(k1, k2)
    return nil
  end

  def unauth(msg) = [401, {}, [msg]]

  def response_from_result(result, prefix)
    body = result.to_firefox(gzip: true)
    filename = "#{prefix}_#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.vernier.json.gz"
    headers = {
      "Content-Type" => "application/octet-stream",
      "Content-Disposition" => "attachment; filename=\"#{filename}\"",
      "Content-Length" => body.bytesize.to_s,
    }
    return Rack::Response.new(body, 200, headers).finish
  end

  # Run this app to control a global process profiler.
  # Call /_vernier?start=true&key=<key> to start the profiler.
  # Call /_vernier?stop=true&key=<key> to stop and download the profile.
  class RackApp
    include Suma::Performance::Vernier

    attr_reader :mode, :interval, :allocation_interval, :memory_usage, :collector, :tempfile

    def initialize(key:, enabled:, interval: nil, allocation_interval: nil, mode: nil, memory_usage: nil)
      @key = key
      @enabled = enabled
      @interval = interval
      @allocation_interval = allocation_interval
      @mode = mode
      @memory_usage = memory_usage
      @collector = nil
      @tempfile = nil
    end

    def call(env)
      return unauth("disabled") unless @enabled

      request = Rack::Request.new(env)

      if (checked = checkauth(request.GET["key"], @key))
        return checked
      end

      start = request.GET.key?("start")
      stop = request.GET.key?("stop")

      if start
        opts = parse_params(request.GET, mode:, interval:, allocation_interval:, memory_usage:)
        @tempfile = Tempfile.new("vernier", binmode: true)
        opts[:out] = @tempfile
        @collector&.send(:finish) # start writes; we just want to finish collecting
        @collector = Vernier::Collector.new(opts.delete(:mode), opts)
        @collector.start
      end
      if stop
        return Rack::Response.new("collector not running", 400, {}).finish if @collector.nil?
        result = @collector.stop
        @collector = nil
        resp = response_from_result(result, "rubyapp")
        @tempfile.unlink
        @tempfile = nil
        return resp
      end
      return Rack::Response.new("ok", 200, {}).finish
    end
  end

  # Rack middlware based on Vernier::Middleware.
  # Add ?vernier=true&vernier_key=<key> to trace the underlying endpoint,
  # and then download the profile instead of the normal response.
  class RackMiddleware
    include Suma::Performance::Vernier

    def initialize(app, enabled:, key:)
      @app = app
      @enabled = enabled
      @key = key
    end

    def call(env)
      return @app.call(env) unless @enabled

      request = Rack::Request.new(env)
      return @app.call(env) unless request.GET.key?("vernier")

      if (checked = checkauth(@key, request.GET["vernier_key"]))
        return checked
      end

      opts = parse_params(request.GET, prefix: "vernier_")
      result = Vernier.trace(**opts) do
        @app.call(env)
      end
      response = response_from_result(result, request.path.tr("/", "_").delete_prefix("_"))
      response[1]["vernier-options"] = opts.to_json
      return response
    end
  end
end
