# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::Programs
  extend Suma::Fixtures

  fixtured_class Suma::Program

  base :program do
    self.period ||= Faker::Suma.number(50..2).days.ago..Faker::Suma.number(2..50).days.from_now
  end

  before_saving do |instance|
    instance.name ||= Suma::Fixtures.translated_text.create
    instance.description ||= Suma::Fixtures.translated_text.create
    instance
  end

  decorator :with_image, presave: true do |o={}|
    o[:program_id] = self.id
    Suma::Fixtures.image.create(**o)
  end

  decorator :expired do
    self.period_end = 1.second.ago
  end

  decorator :future do
    self.period_begin = 1.day.from_now
  end
end
