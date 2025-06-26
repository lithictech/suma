# frozen_string_literal: true

require "rack"

class Rack::SpaRewrite
  ALLOWED_VERBS = ["GET", "HEAD", "OPTIONS"].freeze
  ALLOW_HEADER = ALLOWED_VERBS.join(", ")

  attr_reader :index_mtime

  def initialize(app, index_path:, html_only:)
    @app = app
    @index_path = index_path
    @html_only = html_only
    begin
      @index_mtime = ::File.mtime(@index_path).httpdate
    rescue Errno::ENOENT
      @index_mtime = Time.at(0)
    end
    @index_bytes = nil
    @head = Rack::Head.new(->(env) { get env })
  end

  def call(env)
    # HEAD requests drop the response body, including 4xx error messages.
    @head.call env
  end

  ASSET_EXTS = [".js", ".css", ".png", ".jpg", ".jpeg", ".ico", ".json", ".ttf", ".woff"].freeze

  def get(env)
    request = Rack::Request.new env

    if @html_only && !request.path_info.end_with?(".html")
      # Skip custom logic if we are serving only html paths, and this isn't an html path.
      # html_only is true on the 'first' call of this middleware, when we want to specific.
      return @app.call(env)
    end

    if !@html_only && ASSET_EXTS.any? { |ext| request.path_info.end_with?(ext) }
      # If html_only is false, we are running our fallback logic that serves the index html file
      # for many types of requests that were 404ing. This is usually as-desired.
      # But, if a JS file 404s, we don't want to serve it as an HTML file instead.
      # So if the path extension is an asset type (image, css, js, etc),
      # return a 404 explicitly. We do not want to run the 'fallback' logic here,
      # since we're already at the fallback.
      content = "Not found\n"
      return [404, {"content-type" => "text/plain", "content-length" => content.length}, [content]]
    end

    return [405, {"Allow" => ALLOW_HEADER}, ["Method Not Allowed"]] unless
      ALLOWED_VERBS.include?(request.request_method)

    path_info = Rack::Utils.unescape_path(request.path_info)
    return [400, {}, ["Bad Request"]] unless Rack::Utils.valid_path?(path_info)

    return [200, {"Allow" => ALLOW_HEADER, Rack::CONTENT_LENGTH => "0"}, []] if
      request.options?

    lastmod = ::File.mtime(@index_path)
    lastmodhttp = lastmod.httpdate
    return [304, {}, []] if request.get_header("HTTP_IF_MODIFIED_SINCE") == lastmodhttp

    @index_bytes = ::File.read(@index_path) if @index_bytes.nil? || @index_mtime < lastmodhttp
    headers = {
      Rack::CONTENT_LENGTH => @index_bytes.bytesize,
      Rack::CONTENT_TYPE => "text/html",
      "last-modified" => lastmodhttp,
    }
    return [200, headers, [@index_bytes]]
  end
end
