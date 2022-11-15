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

  one_to_many :fulfillment_options, class: "Suma::Commerce::OfferingFulfillmentOption"
  one_to_many :offering_products, class: "Suma::Commerce::OfferingProduct"
  one_to_many :carts, class: "Suma::Commerce::Cart"

  dataset_module do
    def available_at(t)
      return self.where(Sequel.pg_range(:period).contains(Sequel.cast(t, :timestamptz)))
    end
  end
end

# Table: commerce_offerings
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id             | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at     | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at     | timestamp with time zone |
#  period         | tstzrange                | NOT NULL
#  description_id | integer                  | NOT NULL
# Indexes:
#  commerce_offerings_pkey | PRIMARY KEY btree (id)
# Foreign key constraints:
#  commerce_offerings_description_id_fkey | (description_id) REFERENCES translated_texts(id)
# Referenced By:
#  commerce_carts                        | commerce_carts_offering_id_fkey                        | (offering_id) REFERENCES commerce_offerings(id)
#  commerce_offering_fulfillment_options | commerce_offering_fulfillment_options_offering_id_fkey | (offering_id) REFERENCES commerce_offerings(id)
#  commerce_offering_products            | commerce_offering_products_offering_id_fkey            | (offering_id) REFERENCES commerce_offerings(id)
#  images                                | images_commerce_offering_id_fkey                       | (commerce_offering_id) REFERENCES commerce_offerings(id)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
