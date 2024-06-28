# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::Images
  extend Suma::Fixtures

  fixtured_class Suma::Image

  base :image do
    self.ordinal ||= 0
  end

  before_saving do |instance|
    instance.uploaded_file ||= Suma::Fixtures.uploaded_file.create
    instance
  end

  decorator :for do |o|
    self.associated_object = o
  end
end
