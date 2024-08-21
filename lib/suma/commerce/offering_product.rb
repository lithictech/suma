# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"
require "suma/admin_linked"
class Suma::Commerce::OfferingProduct < Suma::Postgres::Model(:commerce_offering_products)
  include Suma::AdminLinked

  plugin :timestamps
  plugin :money_fields, :customer_price
  plugin :money_fields, :undiscounted_price

  many_to_one :product, class: "Suma::Commerce::Product"
  many_to_one :offering, class: "Suma::Commerce::Offering"

  many_through_many :orders,
                    [
                      [:commerce_checkout_items, :offering_product_id, :checkout_id],
                    ],
                    class: "Suma::Commerce::Order",
                    right_primary_key: :checkout_id,
                    left_primary_key: :id,
                    read_only: true,
                    order: [:created_at, :id]

  dataset_module do
    def available
      return self.where(closed_at: nil)
    end
  end

  def available? = self.closed_at.nil?
  def closed? = !self.available?

  def discounted?
    return false if self.undiscounted_price.nil?
    return self.customer_price < self.undiscounted_price
  end

  def discount_amount
    return self.undiscounted_price - self.customer_price
  end

  # Create and return a new instance with one or both of the given pricing fields modified,
  # and the receiver closed. Offering product prices are immutable,
  # so this is the way we must change pricing.
  # @param customer_price [Money]
  # @param undiscounted_price [Money]
  # @return [Suma::Commerce::OfferingProduct]
  def with_changes(customer_price: nil, undiscounted_price: nil)
    customer_price ||= self.customer_price
    undiscounted_price ||= self.undiscounted_price
    raise ArgumentError, "at least one new pricing field must be passed" if
      customer_price == self.customer_price && undiscounted_price == self.undiscounted_price
    raise Suma::InvalidPrecondition, "cannot change pricing of a closed offering product" if self.closed?
    self.db.transaction do
      self.update(closed_at: Time.now)
      return self.class.create(
        customer_price:,
        undiscounted_price:,
        offering: self.offering,
        product: self.product,
      )
    end
  end

  # Helper to use when we want to modify an offering product.
  # Should only be needed for testing.
  def update_without_validate(**)
    self.set(**)
    return self.save_changes(validate: false)
  end

  def rel_admin_link = "/offering-product/#{self.id}"

  def validate
    super
    return if self.new?
    [:customer_price_cents, :customer_price_currency].each do |col|
      errors.add(col, "cannot change customer price of offering products") if self.changed_columns.include?(col)
    end
  end
end

# Table: commerce_offering_products
# ---------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                          | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                  | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                  | timestamp with time zone |
#  closed_at                   | timestamp with time zone |
#  product_id                  | integer                  | NOT NULL
#  offering_id                 | integer                  | NOT NULL
#  customer_price_cents        | integer                  | NOT NULL
#  customer_price_currency     | text                     | NOT NULL
#  undiscounted_price_cents    | integer                  | NOT NULL
#  undiscounted_price_currency | text                     | NOT NULL
# Indexes:
#  commerce_offering_products_pkey                         | PRIMARY KEY btree (id)
#  commerce_offering_products_product_id_offering_id_index | UNIQUE btree (product_id, offering_id) WHERE closed_at IS NULL
#  commerce_offering_products_offering_id_index            | btree (offering_id)
#  commerce_offering_products_product_id_index             | btree (product_id)
# Foreign key constraints:
#  commerce_offering_products_offering_id_fkey | (offering_id) REFERENCES commerce_offerings(id)
#  commerce_offering_products_product_id_fkey  | (product_id) REFERENCES commerce_products(id)
# Referenced By:
#  commerce_checkout_items | commerce_checkout_items_offering_product_id_fkey | (offering_product_id) REFERENCES commerce_offering_products(id)
# ---------------------------------------------------------------------------------------------------------------------------------------------
