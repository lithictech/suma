# frozen_string_literal: true

require "httparty"

require "appydays/loggable/httparty_formatter"

module Suma::Http
  # Error raised when some API has rate limited us.
  class BaseError < RuntimeError; end

  class Error < BaseError
    attr_reader :response, :body, :uri, :status, :http_method

    def initialize(response, msg=nil)
      @response = response
      @body = response.body
      @headers = response.headers.to_h
      @status = response.code
      @uri = response.request.last_uri.dup
      if @uri.query.present?
        cleaned_params = CGI.parse(@uri.query).map { |k, v| k.include?("secret") ? [k, ".snip."] : [k, v] }
        @uri.query = HTTParty::Request::NON_RAILS_QUERY_STRING_NORMALIZER.call(cleaned_params)
      end
      @http_method = response.request.http_method::METHOD
      super(msg || self.to_s)
    end

    def to_s
      return "HttpError(status: #{self.status}, method: #{self.http_method}, uri: #{self.uri}, body: #{self.body})"
    end

    alias inspect to_s
  end

  def self.user_agent
    return "Suma/#{Suma::RELEASE} https://mysuma.org #{Suma::RELEASE_CREATED_AT}"
  end

  def self.check!(response, **options)
    return if options[:skip_error]
    # All oks are ok
    return if response.code < 300
    # We expect 300s if we aren't following redirects
    return if response.code < 400 && !options[:follow_redirects]
    # Raise for 400s, or 300s if we were meant to follow redirects
    raise Error, response
  end

  def self.get(url, query={}, **, &)
    opts = {query:, headers: {}}.merge(**)
    return self.execute("get", url, **opts, &)
  end

  def self.post(url, body={}, headers: {}, **options, &)
    raise ArgumentError, "must pass :logger keyword" unless options.key?(:logger)
    headers["Content-Type"] ||= "application/json"
    unless body.is_a?(String)
      body = body.to_json if headers["Content-Type"].include?("json")
      body = URI.encode_www_form(body) if headers["Content-Type"] == "application/x-www-form-urlencoded"
    end
    opts = {body:, headers:}.merge(**options)
    return self.execute("post", url, **opts, &)
  end

  def self.execute(method, url, **options, &)
    raise ArgumentError, "must pass :logger keyword" unless options.key?(:logger)
    options[:log_format] ||= :appydays
    options[:headers] ||= {}
    options[:headers]["User-Agent"] = self.user_agent
    r = HTTParty.send(method, url, **options, &)
    self.check!(r, **options)
    return r
  end
end
