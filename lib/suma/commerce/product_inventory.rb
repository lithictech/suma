# frozen_string_literal: true

require "suma/commerce"

class Suma::Commerce::ProductInventory < Suma::Postgres::Model(:commerce_product_inventories)
  plugin :timestamps

  many_to_one :product, class: "Suma::Commerce::Product"
end
