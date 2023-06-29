# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"
require "suma/image"
require "suma/translated_text"
require "suma/admin_linked"

class Suma::Commerce::Offering < Suma::Postgres::Model(:commerce_offerings)
  include Suma::Image::AssociatedMixin
  include Suma::AdminLinked

  plugin :timestamps
  plugin :tstzrange_fields, :period
  plugin :translated_text, :description, Suma::TranslatedText
  plugin :translated_text, :fulfillment_prompt, Suma::TranslatedText
  plugin :translated_text, :fulfillment_confirmation, Suma::TranslatedText

  one_to_many :fulfillment_options, class: "Suma::Commerce::OfferingFulfillmentOption"
  one_to_many :offering_products, class: "Suma::Commerce::OfferingProduct"
  one_to_many :carts, class: "Suma::Commerce::Cart"

  many_to_many :eligibility_constraints,
               class: "Suma::Eligibility::Constraint",
               join_table: :eligibility_offering_associations,
               right_key: :constraint_id,
               left_key: :offering_id

  many_through_many :products,
                    [
                      [:commerce_offering_products, :offering_id, :product_id],
                    ],
                    distinct: :product_id,
                    class: "Suma::Commerce::Product",
                    left_primary_key: :id,
                    right_primary_key: :id,
                    read_only: true,
                    order: [:created_at, :id]
  many_to_one :product_count,
              read_only: true,
              key: :id,
              class: "Suma::Commerce::Offering",
              dataset: proc {
                         ds = Suma::Commerce::OfferingProduct.where(offering_id: id).distinct(:product_id)
                         db.from(ds).select { count(1).as(product_count) }.naked
                       },
              eager_loader: (lambda do |eo|
                               eo[:rows].each { |p| p.associations[:product_count] = nil }
                               ds = Suma::Commerce::OfferingProduct.
                                 where(offering_id: eo[:id_map].keys).
                                 distinct(:product_id)
                               db.from(ds).
                                 select_group(:offering_id).
                                 select_append { count(offering_id).as(product_count) }.
                                 all do |t|
                                 p = eo[:id_map][t.delete(:offering_id)].first
                                 p.associations[:product_count] = t
                               end
                             end)

  def product_count
    # Pick just the 'select' column from the associated object
    return (super || {}).fetch(:product_count, 0)
  end

  many_through_many :orders,
                    [
                      [:commerce_carts, :offering_id, :id],
                      [:commerce_checkouts, :cart_id, :id],
                    ],
                    class: "Suma::Commerce::Order",
                    left_primary_key: :id,
                    right_primary_key: :checkout_id,
                    read_only: true,
                    order: [:created_at, :id]
  many_to_one :order_count,
              read_only: true,
              key: :id,
              class: "Suma::Commerce::Offering",
              dataset: proc {
                Suma::Commerce::Order.where(
                  checkout: Suma::Commerce::Checkout.where(
                    cart: Suma::Commerce::Cart.where(offering_id: id),
                  ),
                ).select { count(1).as(order_count) }.naked
              },
              eager_loader: (lambda do |eo|
                eo[:rows].each { |p| p.associations[:order_count] = nil }
                Suma::Commerce::Order.join(:commerce_checkouts, {id: :checkout_id}).
                  join(:commerce_carts, {id: :cart_id}).
                  where(offering_id: eo[:id_map].keys).
                  select_group(:offering_id).
                  select_append { count(offering_id).as(order_count) }.
                  naked.
                  all do |t|
                  p = eo[:id_map][t.delete(:offering_id)].first
                  p.associations[:order_count] = t
                end
              end)

  def order_count
    # Pick just the 'select' column from the associated object
    return (super || {}).fetch(:order_count, 0)
  end

  dataset_module do
    def available_at(t)
      return self.where(Sequel.pg_range(:period).contains(Sequel.cast(t, :timestamptz)))
    end

    def available_to(member)
      # TODO: add funcitonallity to show only offerings available to specific people based on eligibility constraints
      return self
    end
  end

  def rel_admin_link = "/offering/#{self.id}"

  def order_pick_list
    self.orders.map { |o| o.checkout.items }.flatten
  end

  def timed?
    return !self.begin_fulfillment_at.nil?
  end

  # Call begin_fulfillment on all orders, if this is a 'timed fulfillment' offering.
  # Untimed offerings must have their orders processed manually.
  def begin_order_fulfillment(now:)
    return -1 unless self.timed? && now >= self.begin_fulfillment_at
    checkout = Suma::Commerce::Checkout.where(cart: Suma::Commerce::Cart.where(offering: self))
    orders = Suma::Commerce::Order.where(checkout:).ready_for_fulfillment
    count = 0
    orders.for_update.each do |o|
      count += 1 if o.process(:begin_fulfillment)
    end
    return count
  end
end

# Table: commerce_offerings
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                    | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at            | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at            | timestamp with time zone |
#  period                | tstzrange                | NOT NULL
#  description_id        | integer                  | NOT NULL
#  confirmation_template | text                     | NOT NULL DEFAULT ''::text
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
