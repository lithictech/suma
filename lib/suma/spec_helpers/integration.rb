# frozen_string_literal: true

require "appydays/configurable"
require "httparty"
require "rspec"

require "suma"
require "suma/async"
require "suma/spec_helpers"

raise "integration tests not enabled, this file should not have been evaluated" unless
  Suma::INTEGRATION_TESTS_ENABLED

module Suma::SpecHelpers::Integration
  include Appydays::Configurable
  include Appydays::Loggable

  def self.included(context)
    context.before(:each) do |example|
      raise "Unit tests should not be run during integration tests (or this test needs an :integration flag" unless
        example.metadata[:integration]

      WebMock.allow_net_connect!
    end

    context.after(:each) do
      WebMock.disable_net_connect!
    end
    super
  end

  module_function def with_async_publisher
    sub = Amigo.install_amigo_jobs
    yield
  ensure
    Amigo.unregister_subscriber(sub) if sub
  end

  module_function def url(more)
    return "#{Suma.api_url}#{more}"
  end

  module_function def parse_cookie(resp)
    cookie_hash = HTTParty::CookieHash.new
    resp.get_fields("Set-Cookie")&.each { |c| cookie_hash.add_cookies(c) }
    return cookie_hash
  end

  module_function def store_cookies
    response = yield()
    @stored_cookies = parse_cookie(response)
    Suma::SpecHelpers::Integration.logger.debug "Got cookies: %p" % [stored_cookies]
    return response
  end

  module_function def stored_cookies
    return @stored_cookies
  end

  module_function def valid_testing_address
    return Suma::Address.lookup(
      address1: "1221 SW 4th Ave",
      city: "Portland",
      state_or_province: "OR",
      postal_code: "97204",
    )
  end

  module_function def auth_customer(customer=nil)
    pw = Suma::Fixtures::Members::PASSWORD
    if customer.nil?
      customer = Suma::Fixtures.customer.password(pw).create
    else
      customer.password = pw
      customer.save_changes
    end

    resp = post("/api/v1/auth", body: {phone: customer.us_phone, password: pw})
    expect(resp).to party_status(200)

    return customer
  end

  [:get, :post, :put, :patch, :delete].each do |method|
    define_method(method) do |url_, opts={}|
      store_cookies do
        cookie_header = stored_cookies&.to_cookie_string
        if cookie_header.present?
          opts[:headers] ||= {}
          opts[:headers] = opts[:headers].merge("Cookie" => cookie_header)
        end
        Suma::SpecHelpers::Integration.logger.info "%s %s %s" % [method.upcase, url_, opts]
        HTTParty.send(method, url(url_), opts)
      end
    end
    module_function method
  end
end

# Check that an HTTParty::Response code matches the expected.
RSpec::Matchers.define(:party_status) do |expected_status|
  match do |response|
    response.code == expected_status
  end

  failure_message do |response|
    "expected response code %d, got a %d response instead\nBody: %s" %
      [expected_status, response.code, response.parsed_response]
  end
end

# Match a parsed Response hash (deep symbol keys) against an RSpec matcher.
RSpec::Matchers.define(:party_response) do |matcher|
  match do |response|
    raise "API did not return a hash: #{response.parsed_response}" unless response.parsed_response.is_a?(Hash)
    matcher.matches?(response.parsed_response.deep_symbolize_keys)
  end

  failure_message do
    matcher.failure_message
  end
end
