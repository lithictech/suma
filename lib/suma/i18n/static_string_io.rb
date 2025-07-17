# frozen_string_literal: true

module Suma::I18n::StaticStringIO
  SEEDS_DIR = Suma::I18n::DATA_DIR + "seeds"

  class << self
    def replace_seeds
      Suma::I18n::StaticString.dataset.delete
      self.import_seeds
    end

    # For any static strings in the seed file not in the database,
    # insert them into the database.
    # To first delete seeds, use +replace_seeds+ instead.
    # This method is called as part of the release process. See localization.md for more info.
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
        data.each do |namespace, ns_strings|
          Suma::I18n::StaticString.dataset.
            insert_conflict.
            import([:namespace, :key, :modified_at], ns_strings.keys.map { |k| [namespace, k, modified_at] })
          Suma::I18n::StaticString.each do |ss|
            translated = ns_strings[ss.key]
            next unless translated
            next if ss.text
            ss.update(text: Suma::TranslatedText.create(translated))
          end
        end
      end
    end

    # Export current static strings to seed files.
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
