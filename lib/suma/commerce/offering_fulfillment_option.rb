# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::OfferingFulfillmentOption < Suma::Postgres::Model(:commerce_offering_fulfillment_options)
  plugin :soft_deletes
  plugin :timestamps
  plugin :translated_text, :description, Suma::TranslatedText

  many_to_one :address, class: "Suma::Address"
  many_to_one :offering, class: "Suma::Commerce::Offering"

  dataset_module do
    def pickup
      return self.where(type: 'pickup')
    end
  end

  def pickup? = self.type == 'pickup'
end

# Table: commerce_offering_fulfillment_options
# --------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id              | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at      | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at      | timestamp with time zone |
#  soft_deleted_at | timestamp with time zone |
#  type            | text                     | NOT NULL
#  ordinal         | double precision         | NOT NULL DEFAULT 0
#  description_id  | integer                  | NOT NULL
#  address_id      | integer                  |
#  offering_id     | integer                  | NOT NULL
# Indexes:
#  commerce_offering_fulfillment_options_pkey              | PRIMARY KEY btree (id)
#  commerce_offering_fulfillment_options_offering_id_index | btree (offering_id)
# Foreign key constraints:
#  commerce_offering_fulfillment_options_address_id_fkey     | (address_id) REFERENCES addresses(id)
#  commerce_offering_fulfillment_options_description_id_fkey | (description_id) REFERENCES translated_texts(id)
#  commerce_offering_fulfillment_options_offering_id_fkey    | (offering_id) REFERENCES commerce_offerings(id)
# Referenced By:
#  commerce_checkouts | commerce_checkouts_fulfillment_option_id_fkey | (fulfillment_option_id) REFERENCES commerce_offering_fulfillment_options(id)
# --------------------------------------------------------------------------------------------------------------------------------------------------
