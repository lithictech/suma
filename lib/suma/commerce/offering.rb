# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"
require "suma/image"
require "suma/translated_text"

class Suma::Commerce::Offering < Suma::Postgres::Model(:commerce_offerings)
  include Suma::Image::AssociatedMixin

  plugin :timestamps
  plugin :tstzrange_fields, :period
  plugin :translated_text, :description, Suma::TranslatedText

  one_to_many :offering_products, class: "Suma::Commerce::OfferingProduct"
  one_to_many :carts, class: "Suma::Commerce::Cart"

  dataset_module do
    def available_at(t)
      return self.where(Sequel.pg_range(:period).contains(Sequel.cast(t, :timestamptz)))
    end
  end
end
