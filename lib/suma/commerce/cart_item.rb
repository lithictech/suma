# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::CartItem < Suma::Postgres::Model(:commerce_cart_items)
  plugin :timestamps

  many_to_one :cart, class: "Suma::Commerce::Cart"
  many_to_one :product, class: "Suma::Commerce::Product"
  one_to_one :offering_product,
             class: "Suma::Commerce::OfferingProduct",
             readonly: true,
             eager_loader: (lambda do |eo|
               offering_ids = []
               product_ids = []
               eo[:rows].each do |row|
                 # This implicitly makes another eager query. It should be fine for us though,
                 # the alternative requires joins or more weirdness.
                 offering_ids << row.cart[:offering_id]
                 product_ids << row[:product_id]
               end
               ds = Suma::Commerce::OfferingProduct.where(product_id: product_ids, offering_id: offering_ids)
               by_offering_and_product = ds.all.index_by { |op| [op[:offering_id], op[:product_id]] }
               eo[:rows].each do |row|
                 key = [row.cart[:offering_id], row[:product_id]]
                 row.associations[:offering_product] = by_offering_and_product[key]
               end
             end) do |_ds|
    # Custom block for when we aren't using eager loading
    Suma::Commerce::OfferingProduct.
      where(offering_id: self.cart.offering_id, product_id: self.product_id)
  end

  def available?
    return self.offering_product&.available? || false
  end
end
