# frozen_string_literal: true

require "suma/fixtures"
require "suma/mobility/gbfs_feed"

module Suma::Fixtures::MobilityGbfsFeeds
  extend Suma::Fixtures

  fixtured_class Suma::Mobility::GbfsFeed

  base :mobility_gbfs_feed do
    self.feed_root_url ||= Faker::Internet.url
  end

  before_saving do |instance|
    instance.vendor ||= Suma::Fixtures.vendor.create
    instance
  end
end
