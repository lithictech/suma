# frozen_string_literal: true

require "httparty"

require "appydays/configurable"
require "appydays/loggable/httparty_formatter"

module Suma::Http
  include Appydays::Configurable

  SAFE_METHODS = ["GET", "HEAD", "OPTIONS", "TRACE"].freeze
  UNSAFE_METHODS = ["POST", "PUT", "PATCH", "DELETE", "CONNECT"].freeze

  configurable(:sumahttp) do
    # Keys are hosts ('app.mysuma.org'), values are env vars names ('QUOTAGUARDSTATIC_URL').
    # A value of '{"app.mysuma.org":"QUOTAGUARDSTATIC_URL"}' would proxy all requests to app.mysuma.org
    # through the proxy defined in "QUOTAGUARDSTATIC_URL".
    setting :proxy_vars_for_hosts, {}, convert: ->(v) { JSON.parse(v) }
  end

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

  class << self
    def user_agent
      return "Suma/#{Suma::RELEASE} https://mysuma.org #{Suma::RELEASE_CREATED_AT}"
    end

    def check!(response, **options)
      return if options[:skip_error]
      # All oks are ok
      return if response.code < 300
      # We expect 300s if we aren't following redirects
      return if response.code < 400 && !options[:follow_redirects]
      # Raise for 400s, or 300s if we were meant to follow redirects
      raise Error, response
    end

    def get(url, query={}, **, &)
      opts = {query:, headers: {}}.merge(**)
      return self.execute("get", url, **opts, &)
    end

    def post(url, body={}, headers: {}, **options, &)
      raise ArgumentError, "must pass :logger keyword" unless options.key?(:logger)
      headers["Content-Type"] ||= "application/json"
      unless body.is_a?(String)
        body = body.to_json if headers["Content-Type"].include?("json")
        body = URI.encode_www_form(body) if headers["Content-Type"] == "application/x-www-form-urlencoded"
      end
      opts = {body:, headers:}.merge(**options)
      return self.execute("post", url, **opts, &)
    end

    # Invoke HTTParty to make the http request.
    #
    # @param method [String,Symbol] The HTTP method ('post', 'get', etc.)
    # @param url [String] The URL to call.
    # @param options [Hash] Options including:
    #   +:log_format+ Default to :appydays
    #   +:headers+ Additional headers. Will set 'User-Agent'.
    #   +:http_proxy_url+ Extract proxy fields (:http_proxyaddr, etc) from this URL.
    #   Note that a proxy may be assigned through +proxy_vars_for_hosts+,
    #   refer to it for more information.
    #   Use +false+ to explicitly ignore any configured proxy for the host.
    def execute(method, url, **options, &)
      raise ArgumentError, "must pass :logger keyword" unless options.key?(:logger)
      options[:log_format] ||= :appydays
      options[:headers] ||= {}
      options[:headers]["User-Agent"] = self.user_agent
      self.set_proxy_opts(url, options, options[:http_proxy_url])
      r = HTTParty.send(method, url, **options, &)
      self.check!(r, **options)
      return r
    end

    private def set_proxy_opts(url, options, proxy_url)
      return if proxy_url == false
      if proxy_url.blank?
        # If there's no explicit url, see if it's in the per-host url list.
        url_host = URI(url).host
        proxy_url_env_var = self.proxy_vars_for_hosts[url_host]
        # If it's not there, there's no proxy.
        return if proxy_url_env_var.blank?
        # If the expected proxy url is not in the env, raise an error,
        # since it'd mean we expect to use a proxy that isn't there.
        if (proxy_url = ENV.fetch(proxy_url_env_var, nil)).blank?
          msg = "env var SUMAHTTP_PROXY_VARS_FOR_HOSTS for host #{url_host} referred to " \
                "#{proxy_url_env_var}, but #{proxy_url_env_var} is not set in the environment"
          raise KeyError, msg
        end
      end
      return if proxy_url.blank?
      proxy_uri = URI(proxy_url)
      options[:http_proxyaddr] = proxy_uri.host
      options[:http_proxyport] = proxy_uri.port
      options[:http_proxyuser] = proxy_uri.user
      options[:http_proxypass] = proxy_uri.decoded_password
    end
  end
end
