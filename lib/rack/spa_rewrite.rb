# frozen_string_literal: true

require "rack"

class Rack::SpaRewrite
  ALLOWED_VERBS = ["GET", "HEAD", "OPTIONS"].freeze
  ALLOW_HEADER = ALLOWED_VERBS.join(", ")

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

  def get(env)
    request = Rack::Request.new env
    return @app.call(env) if @html_only && !request.path_info.end_with?(".html")
    return [405, {"Allow" => ALLOW_HEADER}, ["Method Not Allowed"]] unless
      ALLOWED_VERBS.include?(request.request_method)

    path_info = Rack::Utils.unescape_path(request.path_info)
    return [400, {}, ["Bad Request"]] unless Rack::Utils.valid_path?(path_info)

    return [200, {"Allow" => ALLOW_HEADER, CONTENT_LENGTH => "0"}, []] if
      request.options?

    lastmod = ::File.mtime(@index_path)
    lastmodhttp = lastmod.httpdate
    return [304, {}, []] if request.get_header("HTTP_IF_MODIFIED_SINCE") == lastmodhttp

    @index_bytes = ::File.read(@index_path) if @index_bytes.nil? || @index_mtime < lastmodhttp
    headers = {
      "Content-Length" => @index_bytes.bytesize,
      "Content-Type" => "text/html",
      "Last-Modified" => lastmodhttp,
    }
    return [200, headers, [@index_bytes]]
  end
end
