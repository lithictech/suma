# frozen_string_literal: true

require "suma/concurrency"
require "suma/i18n"
require "suma/postgres/model"

# Background thread to build all the missing files after startup,
# and periodically check if any namespaces need modification.
class Suma::I18n::StaticStringRebuilder
  include Appydays::Loggable

  PG_CHANNEL = :static_string_rebuilder
  SHUTDOWN_POLL_INTERVAL = 10 # Allow the thread to cleanly exit by polling instead of blocking

  class << self
    def instance = @instance ||= self.new

    # Use this to send a notification so that all web workers rebuild their locale files.
    def notify_change
      Suma::I18n::StaticString.db.notify(PG_CHANNEL)
    end
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
      # This may be happening live, while the current file is being served, so we need an atomic write
      # which will allow existing open handles to finish on the old version.
      Suma::Concurrency.atomic_write(@dir + "#{locale}_#{rf.namespace}.json") do |f|
        f.write(contents)
      end
    end
  end
end
