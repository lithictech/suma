# frozen_string_literal: true

require "suma/i18n"
require "suma/postgres/model"

class Suma::I18n::StaticString < Suma::Postgres::Model(:i18n_static_strings)
  many_to_one :text, key: :text_id, class: "Suma::TranslatedText"

  class << self
    def static_keys_root = Suma::I18n::DATA_DIR + "static_keys"
    def static_keys_base_file = self.static_keys_root + "#{Suma::I18n.base_namespace}.txt"

    # Run import_namespace for each static keys file, to seed the database.
    def import_all_namespaces(root=self.static_keys_root)
      Dir.glob(root + "*").each do |path|
        import_namespace(path)
      end
    end

    # Upsert all keys in the given file into the static strings table, to seed the database.
    def import_namespace(path)
      t = Time.now
      keys = self.load_keys_from_file(path)
      ns = File.basename(path, ".*")
      self.dataset.insert_conflict.import([:key, :namespace, :modified_at], keys.map { |k| [k, ns, t] })
      self.dataset.
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

    # Use this to send a notification so that all web workers rebuild their locale files.
    def notify_change
      self.db.notify(Rebuilder::PG_CHANNEL)
    end
  end

  def validate
    # TODO:  Ensure key is valid
  end

  # Background thread to build all the missing files after startup,
  # and periodically check if any namespaces need modification.
  class Rebuilder
    include Appydays::Loggable

    PG_CHANNEL = :static_string_rebuilder
    SHUTDOWN_POLL_INTERVAL = 10 # Allow the thread to cleanly exit by polling instead of blocking

    class << self
      def instance = @instance ||= self.new
    end

    attr_reader :last_build

    def initialize(dir=Dir.mktmpdir)
      @dir = Pathname(dir)
      @last_built = Time.at(0)
    end

    def start_watcher
      raise "already started" unless @watcher.nil?
      self.rebuild_outdated
      @watcher = Thread.new do
        loop do
          break if Suma::SHUTTING_DOWN_EVENT.wait(Suma::I18n.static_string_rebuild_interval)
          self.rebuild_outdated
        end
      end
      @listener = Thread.new do
        Sequel.connect(Suma::Postgres::Model.uri, logger: self.logger) do |db|
          loop do
            # Using db.listen with loop: true and a timeout didn't work.
            db.listen(PG_CHANNEL, timeout: SHUTDOWN_POLL_INTERVAL)
            break if Suma::SHUTTING_DOWN.true?
            self.rebuild_outdated
          end
        end
      end
    end

    def join_watcher
      @watcher.join
      @listener.join
    end

    def rebuild_outdated
      now = Time.now
      ns = Suma::I18n::StaticString.fetch_modified_namespaces(@last_built)
      self.write_namespaces(ns)
      @last_built = now
    end

    def path_for(locale:, namespace:) = @dir + "#{locale}_#{namespace}.json"

    # Load all strings for the namespaces using +load_namespace_locale+,
    # and write it to files in the given directory ('en_mynamespace.json', 'es_mynamespace.json').
    def write_namespaces(namespaces)
      return if namespaces.empty?
      rewriter = Suma::I18n::ResourceRewriter.new
      resfiles = []
      Suma::I18n::SUPPORTED_LOCALES.each_key do |locale|
        namespaces.each do |namespace|
          data = Suma::I18n::StaticString.load_namespace_locale(namespace:, locale:)
          rf = Suma::I18n::ResourceRewriter::ResourceFile.new(data, namespace:)
          resfiles << [rf, locale]
        end
      end
      rewriter.prime(*resfiles.map { |r, _| r })
      resfiles.each do |(rf, locale)|
        result = rewriter.to_output(rf)
        contents = Yajl::Encoder.encode(result)
        File.write(@dir + "#{locale}_#{rf.namespace}.json", contents)
      end
    end
  end
end
