# frozen_string_literal: true

require "suma/fixtures"
require "suma/translated_text"

module Suma::Fixtures::TranslatedTexts
  extend Suma::Fixtures

  fixtured_class Suma::TranslatedText

  base :translated_text do
    self.en ||= Faker::Lorem.sentence
    self.es ||= self.en.tr("a", "á").tr("e", "é").tr("i", "í").tr("o", "ó").tr("u", "ú")
  end

  decorator :empty do
    self.en = ""
    self.es = ""
  end
end
