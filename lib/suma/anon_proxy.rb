# frozen_string_literal: true

module Suma::AnonProxy
  include Appydays::Configurable

  configurable(:anon_proxy) do
    setting :postmark_email_template, "#{Suma::RACK_ENV}.m%{member_id}@in-dev.mysuma.org"
    setting :email_relay, "fake-relay"
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

require "suma/anon_proxy/relay"
require "suma/anon_proxy/message_handler"
