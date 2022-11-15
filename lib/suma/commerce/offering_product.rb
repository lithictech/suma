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
    def available
      return self.where(closed_at: nil)
    end
  end

  def available?
    return self.closed_at.nil?
  end

  def discounted?
    return false if self.undiscounted_price.nil?
    return false if self.customer_price == self.undiscounted_price
    return true
  end
end
