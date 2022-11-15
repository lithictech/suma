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

  def self.lookup(member:, offering:)
    return self.find_or_create_or_find(member:, offering:)
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
      item.delete
      self.items.delete(item)
    else
      item.update(quantity:, timestamp: tsval)
    end
  end
end
