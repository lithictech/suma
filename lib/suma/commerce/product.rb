# frozen_string_literal: true

require "suma/commerce"
require "suma/image"
require "suma/postgres/model"

class Suma::Commerce::Product < Suma::Postgres::Model(:commerce_products)
  include Suma::Image::AssociatedMixin

  plugin :timestamps
  plugin :money_fields, :our_cost

  many_to_one :vendor, class: "Suma::Vendor"
end
