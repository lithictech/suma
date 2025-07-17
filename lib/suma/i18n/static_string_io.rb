# frozen_string_literal: true

module Suma::I18n::StaticStringIO
  KEYS_DIR = Suma::I18n::DATA_DIR + "static_keys"
  SEEDS_DIR = Suma::I18n::DATA_DIR + "seeds"

  class << self
    def static_keys_base_file = KEYS_DIR + "#{Suma::I18n.base_namespace}.txt"

    # Run import_namespace for each static keys file, to seed the database.
    def import_all_keys(root=KEYS_DIR)
      Dir.glob(root + "*").each do |path|
        import_namespace_keys(path)
      end
    end

    # Upsert all keys in the given file into the static strings table, to seed the database.
    def import_namespace_keys(path)
      t = Time.now
      keys = self.load_keys_from_file(path)
      ns = File.basename(path, ".*")
      Suma::I18n::StaticString.dataset.
        insert_conflict.import([:key, :namespace, :modified_at], keys.map { |k| [k, ns, t] })
      Suma::I18n::StaticString.dataset.
        exclude(namespace: ns, key: keys).
        where(deprecated: false).
        update(deprecated: true, modified_at: t)
    end

    def load_keys_from_file(path)
      keys = []
      File.open(path) do |f|
        f.each_line do |line|
          line = line.strip
          next if line.blank?
          keys << line
        end
      end
      return keys
    end

    # Replace all static strings with strings from seed files.
    # Use when bootstrapping a new database, after initial migration, or as needed in development.
    def import_seeds
      modified_at = Time.now
      data = Suma::I18n::AutoHash.new
      SEEDS_DIR.glob("*").each do |locale_dir|
        locale_dir.glob("*").each do |path|
          j = JSON.load_file(path)
          j = Suma::I18n.flatten_hash(j)
          namespace = path.basename(".*").to_s
          locale = locale_dir.basename(".*").to_s
          j.each do |key, text|
            data[namespace][key][locale] = text
          end
        end
      end
      Suma::I18n::StaticString.db.transaction do
        Suma::I18n::StaticString.dataset.delete
        data.each do |namespace, ns_strings|
          Suma::I18n::StaticString.dataset.
            import([:namespace, :key, :modified_at], ns_strings.keys.map { |k| [namespace, k, modified_at] })
          Suma::I18n::StaticString.each do |ss|
            translated = ns_strings[ss.key]
            next unless translated
            ss.update(text: Suma::TranslatedText.create(translated))
          end
        end
      end
    end

    # Export current static strings to seed files.
    # Use to update the seeds so bootstrapping will give better results as the frontend cahnges.
    def export_seeds
      data = Suma::I18n::AutoHash.new
      Suma::I18n::StaticString.dataset.where(deprecated: false).each do |ss|
        Suma::I18n.enabled_locale_codes.each do |lc|
          data[ss.namespace][lc][ss.key] = ss.text&.send(lc) || ""
        end
      end
      Suma::I18n.enabled_locale_codes.each { |lc| FileUtils.mkdir_p(SEEDS_DIR + lc) }
      data.each do |namespace, ns_strings|
        ns_strings.each do |locale_code, translated|
          path = SEEDS_DIR + locale_code + (namespace + ".json")
          File.write(path, JSON.pretty_generate(translated))
        end
      end
    end
  end
end
