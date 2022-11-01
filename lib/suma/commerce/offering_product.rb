# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::OfferingProduct < Suma::Postgres::Model(:commerce_offering_products)
  plugin :timestamps
  plugin :money_fields, :customer_price
  plugin :money_fields, :undiscounted_price

  many_to_one :product, class: "Suma::Commerce::Product"
  many_to_one :offering, class: "Suma::Commerce::Offering"

  dataset_module do
    def available_with(offering_id)
      return self.where(offering_id:, closed_at: nil)
    end
  end
end
