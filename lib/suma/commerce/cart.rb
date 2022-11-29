# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::Cart < Suma::Postgres::Model(:commerce_carts)
  class ProductUnavailable < StandardError; end

  class ActualProductUnavailable < ProductUnavailable
    def initialize(product, offering)
      super("Product[#{product.id}] #{product.name.en} is unavailable " \
            "in Offering[#{offering.id}] #{offering.description.en}")
    end
  end

  class OutOfOrderUpdate < StandardError
    def initialize(cart_item, timestamp)
      super("CartItem[#{cart_item.id}] #{cart_item.product.name.en} has a timestamp of #{cart_item.timestamp}, " \
            "and cannot be updated by #{timestamp}")
    end
  end

  plugin :timestamps

  many_to_one :member, class: "Suma::Member"
  many_to_one :offering, class: "Suma::Commerce::Offering"
  one_to_many :items, class: "Suma::Commerce::CartItem"
  one_to_many :checkouts, class: "Suma::Commerce::Checkout"
  one_to_many :purchased_checkout_items,
              class: "Suma::Commerce::CheckoutItem",
              read_only: true,
              key: :id,
              dataset: lambda {
                         Suma::Commerce::CheckoutItem.where(
                           checkout: self.checkouts_dataset.unordered.where(
                             order: Suma::Commerce::Order.exclude(order_status: "canceled"),
                           ),
                         ).select_group(:offering_product_id).
                           select_append(Sequel.function(:sum, :immutable_quantity).as(:immutable_quantity))
                       },
              eager_loader: (proc do |eo|
                               eo[:rows].each { |p| p.associations[:purchased_checkout_items] = nil }
                               Suma::Commerce::CheckoutItem.where(
                                 checkout: Suma::Commerce::Checkout.where(
                                   cart_id: eo[:id_map].keys,
                                   order: Suma::Commerce::Order.exclude(order_status: "canceled"),
                                 ),
                               ).select_group(:offering_product_id).
                                 select_append(Sequel.function(:sum, :immutable_quantity).as(:immutable_quantity)).
                                 naked.
                                 all do |ci|
                                 p = eo[:id_map][ci.values.delete(:offering_product_id)].first
                                 p.associations[:purchased_checkout_items] = ci
                               end
                             end)

  def self.lookup(member:, offering:)
    return self.find_or_create_or_find(member:, offering:)
  end

  def customer_cost
    return self.items.sum(Money.new(0)) { |ci| ci.offering_product.customer_price * ci.quantity }
  end

  IGNORE = Object.new.freeze

  # Add, updated, or remove (quantity <= 0 ) the given product on this cart.
  #
  # To avoid out-of-order updates,
  # we require a (fractional millisecond integer) timestamp when setting an item,
  # passed in by the client, representing when they took the action.
  # When adding an item, nil is acceptable; otherwise, the timestamp must be greater than
  # the timestamp stored on the row.
  #
  # If the timestamp is invalid, raise OutOfOrderUpdate.
  # Usualluy the API will catch this and ignore it,
  # since it usually means the requests came in out-of-order.
  def set_item(product, quantity, timestamp:)
    raise ProductUnavailable, "Product (nil) not available" if product.nil?
    item = self.items.find { |it| it.product === product }
    tsval = timestamp == IGNORE ? 0 : (timestamp || 0)
    if item.nil?
      return if quantity <= 0
      raise ActualProductUnavailable.new(product, self.offering) if
        self.offering.offering_products_dataset.available.where(product:).empty?
      self.add_item(product:, quantity:, timestamp: tsval)
      return
    end
    bad_ts = timestamp != IGNORE && (timestamp.nil? || timestamp <= item.timestamp)
    raise OutOfOrderUpdate.new(item, timestamp) if bad_ts
    if quantity <= 0
      item.checkout_items_dataset.delete
      item.delete
      self.items.delete(item)
    else
      item.update(quantity:, timestamp: tsval)
    end
  end

  # This seems like a reasonable default...
  DEFAULT_MAX_QUANTITY = 12

  def max_quantity_for(offering_product)
    product = offering_product.product
    max_order = product.max_quantity_per_order
    max_offering = product.max_quantity_per_offering
    return DEFAULT_MAX_QUANTITY if max_order.nil? && max_offering.nil?

    items_already_in_offering = self.purchased_checkout_items.
      to_h { |row| [row.offering_product.id, row.quantity] }
    existing = items_already_in_offering.fetch(offering_product.id, 0)

    return [max_order, max_offering].compact.min - existing
  end

  def product_noncash_ledger_contribution_amount(offering_product, now: Time.now)
    contribs = self.member.payment_account!.find_chargeable_ledgers(
      offering_product.product,
      offering_product.customer_price,
      now:,
      remainder_ledger: :ignore,
      calculation_context: Suma::Payment::CalculationContext.new,
      exclude_up: [Suma::Vendor::ServiceCategory.cash],
    )
    return contribs.sum(Money.new(0), &:amount)
  end

  def noncash_ledger_contribution_amount(now: Time.now)
    contribs = Suma::Commerce::Checkout.ledger_charge_contributions(
      payment_account: self.member.payment_account!,
      priced_items: self.items,
      now:,
      remainder_ledger: :ignore,
      exclude_up: [Suma::Vendor::ServiceCategory.cash],
    )
    return contribs.sum(Money.new(0), &:amount)
  end
end

# Table: commerce_carts
# -------------------------------------------------------------------------------------------------
# Columns:
#  id          | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at  | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at  | timestamp with time zone |
#  member_id   | integer                  | NOT NULL
#  offering_id | integer                  | NOT NULL
# Indexes:
#  commerce_carts_pkey                        | PRIMARY KEY btree (id)
#  commerce_carts_member_id_offering_id_index | UNIQUE btree (member_id, offering_id)
# Foreign key constraints:
#  commerce_carts_member_id_fkey   | (member_id) REFERENCES members(id)
#  commerce_carts_offering_id_fkey | (offering_id) REFERENCES commerce_offerings(id)
# Referenced By:
#  commerce_cart_items | commerce_cart_items_cart_id_fkey | (cart_id) REFERENCES commerce_carts(id)
#  commerce_checkouts  | commerce_checkouts_cart_id_fkey  | (cart_id) REFERENCES commerce_carts(id)
# -------------------------------------------------------------------------------------------------
