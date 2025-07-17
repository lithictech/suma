# frozen_string_literal: true

require "suma/i18n"
require "suma/postgres/model"

class Suma::I18n::StaticString < Suma::Postgres::Model(:i18n_static_strings)
  many_to_one :text, key: :text_id, class: "Suma::TranslatedText"

  class << self
    # Read all the strings out of the database for the given namespace and locale.
    # Return it in a form that can be passed to ResourceRewriter.
    def load_namespace_locale(namespace:, locale:)
      locale = locale.to_sym
      ds = self.namespace_locale_dataset(namespace:, locale:)
      h = {}
      ds.naked.each do |row|
        h[row.fetch(:key)] = row.fetch(locale) || ""
      end
      h = nest_hash(h)
      return h
    end

    # Return a dataset for the key and translated text of the given locale
    # for all undeprecated rows in th enamespace.
    def namespace_locale_dataset(namespace:, locale:)
      ds = self.dataset.
        exclude(deprecated: true).
        where(namespace:).
        left_join(:translated_texts, id: :text_id).
        select(:key, locale.to_sym)
      return ds
    end

    # Turn a hash like {x.y: 1, x.z: 2} into {x: {y: 1, z: 2}}
    def nest_hash(h)
      result = Suma::I18n::AutoHash.new
      h.each do |k, v|
        hpart = result
        parts = k.split(".")
        parts[...-1].each do |p|
          hpart = hpart[p]
        end
        hpart[parts.last] = v
      end
      return result
    end

    # Return all namespaces that have been modified +since+.
    def fetch_modified_namespaces(since)
      return self.
          exclude(deprecated: true).
          distinct(:namespace).
          where { modified_at > since }.
          select_map(:namespace)
    end
  end

  def needs_text?
    return true if self.text_id.nil?
    return Suma::I18n.enabled_locale_codes.any? { |c| self.text.send(c).blank? }
  end

  def validate
    super
    validates_format(/^[a-z0-9_.]+$/, :key)
    validates_format(/^[a-z0-9_.]+$/, :namespace)
  end
end
