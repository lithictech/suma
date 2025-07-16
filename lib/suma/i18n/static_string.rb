# frozen_string_literal: true

require "suma/i18n"
require "suma/postgres/model"

class Suma::I18n::StaticString < Suma::Postgres::Model(:i18n_static_strings)
  many_to_one :text, key: :text_id, class: "Suma::TranslatedText"

  class << self
    # Run import_namespace for each static keys file, to seed the database.
    def import_all_namespaces(root=Suma::I18n::DATA_DIR + "static_keys")
      Dir.glob(root + "*").each do |path|
        import_namespace(path)
      end
    end

    # Upsert all keys in the given file into the static strings table, to seed the database.
    def import_namespace(path)
      ns = File.basename(path, ".*")
      t = Time.now
      keys = []
      File.open(path) do |f|
        f.each_line do |line|
          line = line.strip
          next if line.blank?
          keys << line
        end
      end
      self.dataset.insert_conflict.import([:key, :namespace, :modified_at], keys.map { |k| [k, ns, t] })
      self.dataset.
        exclude(namespace: ns, key: keys).
        where(deprecated: false).
        update(deprecated: true, modified_at: t)
    end

    # Read all the strings out of the database for the given namespace and locale.
    # Return it in a form that can be passed to ResourceRewriter.
    def load_namespace_locale(namespace:, locale:)
      locale = locale.to_sym
      ds = self.dataset.
        exclude(deprecated: true).
        where(namespace:).
        left_join(:translated_texts, id: :text_id).
        select(:key, locale)
      h = {}
      ds.naked.each do |row|
        h[row.fetch(:key)] = row.fetch(locale) || ""
      end
      h = nest_hash(h)
      return h
    end

    # Turn a hash like {x.y: 1, x.z: 2} into {x: {y: 1, z: 2}}
    def nest_hash(h)
      result = AutoHash.new
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

    # Load all strings for the namespace using +load_namespace_locale+,
    # and write it to files in the given directory ('en.json', 'es.json').
    def write_namespace(dir, namespace, rewriter: Suma::I18n::ResourceRewriter.new)
      resfiles = []
      Suma::I18n::SUPPORTED_LOCALES.each_key do |locale|
        data = self.load_namespace_locale(namespace:, locale:)
        rf = Suma::I18n::ResourceRewriter::ResourceFile.new(data, namespace:)
        resfiles << [rf, locale]
      end
      rewriter.prime(*resfiles.map { |r, _| r })
      resfiles.each do |(rf, locale)|
        result = rewriter.to_output(rf)
        contents = Yajl::Encoder.encode(result)
        File.write(Pathname(dir) + "#{locale}_#{namespace}.json", contents)
      end
    end

    # Run +write_namespace+ for all namespaces return3ed from +fetch_namespaces+.
    def write_all_namespaces(dir)
      namespaces = self.fetch_namespaces
      rewriter = Suma::I18n::ResourceRewriter.new
      namespaces.each do |namespace|
        self.write_namespace(dir, namespace, rewriter:)
      end
    end

    def fetch_namespaces
      return self.exclude(deprecated: true).distinct(:namespace).select_map(:namespace)
    end

    def fetch_modified_namespaces(since)
      return self.
          exclude(deprecated: true).
          distinct(:namespace).
          where { modified_at > since }.
          select_map(:namespace)
    end
  end

  class AutoHash < Hash
    def initialize(*)
      super
      self.default_proc = proc { |h, k| h[k] = AutoHash.new }
    end
  end
end
