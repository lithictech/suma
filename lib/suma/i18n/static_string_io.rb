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
    def import_seeds(namespaces: nil)
      namespaces = Array(namespaces) if namespaces
      modified_at = Time.now
      data = Suma::I18n::AutoHash.new
      SEEDS_DIR.glob("*").each do |locale_dir|
        locale_dir.glob("*").each do |path|
          namespace = path.basename(".*").to_s
          next if namespaces && !namespaces.include?(namespace)
          j = JSON.load_file(path)
          j = Suma::I18n.flatten_hash(j)
          locale = locale_dir.basename(".*").to_s
          j.each do |key, text|
            data[namespace][key][locale] = text
          end
        end
      end
      locale_columns = Suma::I18n::SUPPORTED_LOCALES.keys.map(&:to_sym)
      Suma::I18n::StaticString.db.transaction do
        data.each do |namespace, ns_strings|
          Suma::I18n::StaticString.dataset.
            insert_conflict.
            import([:namespace, :key, :modified_at], ns_strings.keys.map do |k|
                                                       [namespace, k, modified_at]
                                                     end, return: :primary_key,)
          static_strings_to_update = []
          translated_texts_to_insert = []
          Suma::I18n::StaticString.all.each do |ss|
            translated = ns_strings[ss.key]
            next unless translated
            next if ss.text
            static_strings_to_update << ss
            translated.symbolize_keys!
            # Every row for bulk insert needs the same keys
            locale_columns.each { |c| translated[c] = "" unless translated.key?(c) }
            translated_texts_to_insert << translated
          end
          created_text_ids = Suma::TranslatedText.dataset.
            multi_insert(translated_texts_to_insert, return: :primary_key)
          update_sqls = static_strings_to_update.zip(created_text_ids).map do |(sstr, tt_pk)|
            Suma::I18n::StaticString.dataset.where(id: sstr.id).update_sql(text_id: tt_pk)
          end
          Suma::I18n::StaticString.db << update_sqls.join("; ")
        end
      end
    end

    # Export current static strings to seed files.
    # Use compact formatting mostly when testing.
    def export_seeds(compact: false)
      data = Suma::I18n::AutoHash.new
      Suma::I18n::StaticString.dataset.where(deprecated: false).order(:namespace, :key).each do |ss|
        Suma::I18n.enabled_locale_codes.each do |lc|
          data[ss.namespace][lc][ss.key] = ss.text&.send(lc) || ""
        end
      end
      Suma::I18n.enabled_locale_codes.each { |lc| FileUtils.mkdir_p(SEEDS_DIR + lc) }
      data.each do |namespace, ns_strings|
        ns_strings.each do |locale_code, translated|
          path = SEEDS_DIR + locale_code + (namespace + ".json")
          j = compact ? JSON.generate(translated) : JSON.pretty_generate(translated)
          File.write(path, j)
        end
      end
    end
  end
end
