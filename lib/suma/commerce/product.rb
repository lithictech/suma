# frozen_string_literal: true

require "suma/commerce"
require "suma/image"
require "suma/postgres/model"

class Suma::Commerce::Product < Suma::Postgres::Model(:commerce_products)
  include Suma::Image::AssociatedMixin

  plugin :timestamps
  plugin :money_fields, :our_cost
  plugin :translated_text, :name, Suma::TranslatedText
  plugin :translated_text, :description, Suma::TranslatedText

  many_to_one :vendor, class: "Suma::Vendor"
end
