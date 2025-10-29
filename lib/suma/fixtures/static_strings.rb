# frozen_string_literal: true

require "suma/fixtures"
require "suma/i18n/static_string"

module Suma::Fixtures::StaticStrings
  extend Suma::Fixtures

  fixtured_class Suma::I18n::StaticString

  base :static_string do
    self.key ||= SecureRandom.hex(4)
    self.namespace ||= SecureRandom.hex(2)
    self.modified_at ||= Time.now
  end

  decorator :text do |en=Faker::Lorem.sentence, **more|
    self.text = Suma::Fixtures.translated_text.create(en:, **more)
  end

  decorator :message do |template, transport|
    crit = template.static_string_criteria(transport)
    self.set(crit)
  end

  decorator :deprecated do |t=Time.now|
    self.deprecated_at = t
  end
end
