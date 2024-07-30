# frozen_string_literal: true

require "appydays/configurable"
require "url_shortener"

module Suma::UrlShortener
  include Appydays::Configurable

  ROOT_PATH = "/r"

  configurable(:url_shortener) do
    setting :database_url, ENV.fetch("DATABASE_URL", "postgres:/suma_test")
    setting :table, :url_shortener
    setting :not_found_url, "https://mysuma.org/404"
    setting :byte_size, 2
    setting :disabled, false
  end

  class << self
    # @return [UrlShortener]
    def new_shortener(**kw)
      opts = {
        conn: Sequel.connect(self.database_url),
        table: self.table,
        root: Suma.api_host + ROOT_PATH,
        not_found_url: self.not_found_url,
        byte_size: self.byte_size,
      }
      opts.merge!(kw)
      return ::UrlShortener.new(**opts)
    end

    def enabled? = !self.disabled

    # @return [UrlShortener]
    def shortener
      return nil unless self.enabled?
      return @shortener ||= new_shortener
    end
  end
end
