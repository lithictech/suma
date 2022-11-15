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

# Table: commerce_products
# ---------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at        | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at        | timestamp with time zone |
#  vendor_id         | integer                  | NOT NULL
#  our_cost_cents    | integer                  | NOT NULL
#  our_cost_currency | text                     | NOT NULL
#  name_id           | integer                  | NOT NULL
#  description_id    | integer                  | NOT NULL
# Indexes:
#  commerce_products_pkey | PRIMARY KEY btree (id)
# Foreign key constraints:
#  commerce_products_description_id_fkey | (description_id) REFERENCES translated_texts(id)
#  commerce_products_name_id_fkey        | (name_id) REFERENCES translated_texts(id)
#  commerce_products_vendor_id_fkey      | (vendor_id) REFERENCES vendors(id)
# Referenced By:
#  commerce_cart_items        | commerce_cart_items_product_id_fkey        | (product_id) REFERENCES commerce_products(id)
#  commerce_offering_products | commerce_offering_products_product_id_fkey | (product_id) REFERENCES commerce_products(id)
#  images                     | images_commerce_product_id_fkey            | (commerce_product_id) REFERENCES commerce_products(id)
# ---------------------------------------------------------------------------------------------------------------------------------
