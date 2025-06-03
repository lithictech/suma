# frozen_string_literal: true

module Suma::AnonProxy
  include Appydays::Configurable

  configurable(:anon_proxy) do
    setting :postmark_email_template, "#{Suma::RACK_ENV}.m%{member_id}@in-dev.mysuma.org"
    setting :signalwire_relay_number, ""
    setting :email_relay, "fake-email-relay"
    setting :phone_relay, "fake-phone-relay"
    setting :access_code_poll_timeout, 25
    setting :access_code_poll_interval, 3
  end

  class ParsedMessage < Suma::TypedStruct
    attr_reader :message_id, :to, :from, :content, :timestamp

    # @!attribute message_id
    # @return [String]

    # @!attribute to
    # @return [String]

    # @!attribute from
    # @return [String]

    # @!attribute content
    # @return [String]
    #
    # @!attribute timestamp
    # @return [Time]
  end
end

require "suma/anon_proxy/auth_to_vendor"
require "suma/anon_proxy/relay"
require "suma/anon_proxy/message_handler"
