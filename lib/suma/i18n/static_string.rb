# frozen_string_literal: true

require "suma/i18n"
require "suma/postgres/model"

class Suma::I18n::StaticString < Suma::Postgres::Model(:i18n_static_strings)
  many_to_one :translated_text, class: "Suma::TranslatedText"

  class << self
    def upsert_keys_from_file(path=Suma::I18n::DATA_DIR + "static_string_keys.txt")
      t = Time.now
      keys = []
      File.open(path) do |f|
        f.each_line do |line|
          line = line.strip
          next if line.blank?
          keys << line
        end
      end
      self.dataset.insert_conflict.import([:key, :modified_at], keys.map { |k| [k, t] })
      self.dataset.
        exclude(key: keys).
        where(deprecated: false).
        update(deprecated: true, modified_at: t)
    end
  end
end
