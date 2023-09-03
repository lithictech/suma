# frozen_string_literal: true

require "browser/accept_language"
module SequelTranslatedText
  VERSION = "0.0.1"

  class NoContext < StandardError; end

  class << self
    attr_accessor :default_language

    def language(*langarg, &block)
      lang = langarg.first
      raise ArgumentError, "use language=(lang) if not using a block" if lang && block.nil?
      return Thread.current[:translated_text_lang] if block.nil?
      orig = Thread.current[:translated_text_lang]
      Thread.current[:translated_text_lang] = lang
      begin
        return yield
      ensure
        Thread.current[:translated_text_lang] = orig
      end
    end

    def language!
      lang = self.language
      return lang if lang
      raise NoContext, "must use language=(lang) or language(lang, &block)"
    end

    def language=(lang)
      Thread.current[:translated_text_lang] = lang
    end
  end

  class RackMiddleware
    def initialize(app, languages:)
      @app = app
      raise ArgumentError, "languages cannot be empty" if languages.empty?
      @languages = languages
      @language_strings = Set.new(languages.map(&:to_s))
    end

    def call(env)
      accept = env.fetch("HTTP_ACCEPT_LANGUAGE", @languages.first.to_s)

      request_langs = Browser::AcceptLanguage.parse(accept)
      language = request_langs.find { |al| @language_strings.include?(al.full) }&.full
      language ||= request_langs.find { |al| @language_strings.include?(al.code) }&.code
      language ||= @languages.first
      status, headers, body = SequelTranslatedText.language(language) do
        @app.call(env)
      end
      headers["Content-Language"] = language.to_s
      return [status, headers, body]
    end
  end

  # Mixin for 'translated text' database models.
  # Adds an +all=+ method that assigns the argument as the value for all text columns.
  # NOTE: If the model has non-language text columns, implement +all_languages+.
  # It should return the language column names, like `[:en, :es]`.
  module Model
    def all=(value)
      all_langs = if self.respond_to?(:all_languages)
                    self.all_languages
        else
          self.class.columns.select { |col| self.class.db_schema[col][:type] == :string }
        end
      all_langs.each { |la| self[la] = value }
    end

    def current
      return self.send(SequelTranslatedText.language!)
    end
  end
end
