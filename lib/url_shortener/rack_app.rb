# frozen_string_literal: true

require "url_shortener"

class UrlShortener::RackApp
  # @param [UrlShortener] url_shortener
  def initialize(url_shortener)
    @url_shortener = url_shortener
  end

  def call(env)
    req = Rack::Request.new(env)
    return [405, {}, [""]] unless ["HEAD", "GET"].include?(req.request_method)
    resolved = @url_shortener.resolve_short_url(req.path)
    location = resolved || @url_shortener.not_found_url
    body = "<html><body>This content has moved to <a href=\"#{location}\">#{location}</a></body></html>"
    return [302, {"Location" => location}, [body]]
  end
end
