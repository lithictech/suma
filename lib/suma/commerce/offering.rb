# frozen_string_literal: true

require "suma/admin_linked"
require "suma/postgres/model"
require "suma/commerce"
require "suma/image"
require "suma/has_activity_audit"
require "suma/program/has"
require "suma/translated_text"

class Suma::Commerce::Offering < Suma::Postgres::Model(:commerce_offerings)
  include Suma::Postgres::HybridSearch
  include Suma::Image::SingleAssociatedMixin
  include Suma::AdminLinked
  include Suma::HasActivityAudit

  plugin :hybrid_search
  plugin :timestamps
  plugin :tstzrange_fields, :period
  plugin :association_pks
  plugin :translated_text, :description, Suma::TranslatedText
  plugin :translated_text, :fulfillment_prompt, Suma::TranslatedText
  plugin :translated_text, :fulfillment_confirmation, Suma::TranslatedText
  plugin :translated_text, :fulfillment_instructions, Suma::TranslatedText

  many_to_many :programs,
               class: "Suma::Program",
               join_table: :programs_commerce_offerings,
               left_key: :offering_id,
               right_key: :program_id

  one_to_many :fulfillment_options, class: "Suma::Commerce::OfferingFulfillmentOption"
  one_to_many :offering_products, class: "Suma::Commerce::OfferingProduct"
  one_to_many :carts, class: "Suma::Commerce::Cart"

  many_to_many :programs,
               class: "Suma::Program",
               join_table: :programs_commerce_offerings,
               left_key: :offering_id
  include Suma::Program::Has

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

  one_to_many :total_ordered_items_by_member,
              read_only: true,
              key: :id,
              class: "Suma::Commerce::Offering",
              dataset: proc {
                Suma::Commerce::Order.dataset.uncanceled.
                  join(:commerce_checkouts, {id: :checkout_id}).
                  join(:commerce_checkout_items, {checkout_id: :id}).
                  join(:commerce_carts, {id: Sequel[:commerce_checkouts][:cart_id]}).
                  where(offering_id: id).
                  select_group(:member_id).
                  select_append { coalesce(sum(immutable_quantity), 0).as(ordered_quantity) }.
                  naked
              },
              eager_loader: (lambda do |eo|
                eo[:rows].each { |p| p.associations[:total_ordered_items_by_member] = [] }
                Suma::Commerce::Order.dataset.uncanceled.
                  join(:commerce_checkouts, {id: :checkout_id}).
                  join(:commerce_checkout_items, {checkout_id: :id}).
                  join(:commerce_carts, {id: Sequel[:commerce_checkouts][:cart_id]}).
                  where(offering_id: eo[:id_map].keys).
                  select_group(:offering_id, :member_id).
                  select_append { coalesce(sum(immutable_quantity), 0).as(ordered_quantity) }.
                  naked.
                  all do |t|
                  p = eo[:id_map][t.delete(:offering_id)].first
                  p.associations[:total_ordered_items_by_member] << t
                end
              end)

  # Hash of a member id, to the total amount of things they have ordered in this offering.
  # Excludes canceled orders.
  def total_ordered_items_by_member
    sup = super || []
    return sup.to_h { |r| [r.fetch(:member_id), r.fetch(:ordered_quantity)] }
  end

  # Total items ordered across all orders, excluding canceled.
  def total_ordered_items = total_ordered_items_by_member.values.sum

  dataset_module do
    def available_at(t)
      return self.where(Sequel.pg_range(:period).contains(Sequel.cast(t, :timestamptz)))
    end
  end

  # @!attribute max_ordered_items_cumulative
  # @return [Integer]

  # @!attribute max_ordered_items_per_member
  # @return [Integer]

  def rel_admin_link = "/offering/#{self.id}"

  def rel_app_link = "/food/#{self.id}"

  def timed?
    return !self.begin_fulfillment_at.nil?
  end

  def available_at?(t)
    return self.period.cover?(t)
  end

  # Return +period_end+ if it is soon enough to matter, +nil+ if not.
  # We do not need to display closing information for offerings that end so far in the future.
  def period_end_visible = Suma::Program.period_end_or_nil(self.period_end)

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

  def hybrid_search_fields
    return [
      :description,
      :period_begin,
      :period_end,
    ]
  end
end

require "suma/commerce/offering_picklist"

# Table: commerce_offerings
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                           | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                   | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                   | timestamp with time zone |
#  period                       | tstzrange                | NOT NULL
#  description_id               | integer                  | NOT NULL
#  confirmation_template        | text                     | NOT NULL DEFAULT ''::text
#  begin_fulfillment_at         | timestamp with time zone |
#  fulfillment_prompt_id        | integer                  | NOT NULL
#  fulfillment_confirmation_id  | integer                  | NOT NULL
#  max_ordered_items_cumulative | integer                  |
#  max_ordered_items_per_member | integer                  |
#  fulfillment_instructions_id  | integer                  | NOT NULL
#  search_content               | text                     |
#  search_embedding             | vector(384)              |
#  search_hash                  | text                     |
# Indexes:
#  commerce_offerings_pkey                          | PRIMARY KEY btree (id)
#  commerce_offerings_begin_fulfillment_at_index    | btree (begin_fulfillment_at)
#  commerce_offerings_search_content_tsvector_index | gin (to_tsvector('english'::regconfig, search_content))
# Foreign key constraints:
#  commerce_offerings_description_id_fkey              | (description_id) REFERENCES translated_texts(id)
#  commerce_offerings_fulfillment_confirmation_id_fkey | (fulfillment_confirmation_id) REFERENCES translated_texts(id)
#  commerce_offerings_fulfillment_instructions_id_fkey | (fulfillment_instructions_id) REFERENCES translated_texts(id)
#  commerce_offerings_fulfillment_prompt_id_fkey       | (fulfillment_prompt_id) REFERENCES translated_texts(id)
# Referenced By:
#  commerce_carts                        | commerce_carts_offering_id_fkey                        | (offering_id) REFERENCES commerce_offerings(id)
#  commerce_offering_fulfillment_options | commerce_offering_fulfillment_options_offering_id_fkey | (offering_id) REFERENCES commerce_offerings(id)
#  commerce_offering_products            | commerce_offering_products_offering_id_fkey            | (offering_id) REFERENCES commerce_offerings(id)
#  eligibility_offering_associations     | eligibility_offering_associations_offering_id_fkey     | (offering_id) REFERENCES commerce_offerings(id)
#  images                                | images_commerce_offering_id_fkey                       | (commerce_offering_id) REFERENCES commerce_offerings(id)
#  programs_commerce_offerings           | programs_commerce_offerings_offering_id_fkey           | (offering_id) REFERENCES commerce_offerings(id)
#  vendible_groups_commerce_offerings    | vendible_groups_commerce_offerings_offering_id_fkey    | (offering_id) REFERENCES commerce_offerings(id)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
