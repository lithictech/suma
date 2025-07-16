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
end
