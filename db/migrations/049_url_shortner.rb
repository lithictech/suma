# frozen_string_literal: true

Sequel.migration do
  up do
    require "suma/url_shortener"

    Suma::UrlShortener.new_shortener(conn: self).create_table
  end

  down do
    require "suma/url_shortener"

    drop_table Suma::UrlShortener.new_shortener.table
  end
end
