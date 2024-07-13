# frozen_string_literal: true

require "url_shortener"

module UrlShortener::SpecHelpers
  RSpec::Matchers.define(:be_a_shortlink_to) do |expected|
    match do |str|
      break false if str.blank?
      short_id = str.split("/").last
      resolved = url_shortener.resolve_short_id(short_id)
      resolved == expected
    end

    failure_message do |str|
      "No shortened URL found for #{str.inspect}"
    end
  end
end
