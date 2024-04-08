# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Commerce::Order < Suma::Postgres::Model(:commerce_orders)
  include Suma::AdminLinked

  FULFILLABLE_ORDER_STATUSES = ["open", "completed"].freeze

  plugin :state_machine
  plugin :timestamps

  one_to_many :audit_logs, class: "Suma::Commerce::OrderAuditLog", order: Sequel.desc(:at)
  many_to_one :checkout, class: "Suma::Commerce::Checkout"
  one_to_many :charges, class: "Suma::Charge", key: :commerce_order_id

  many_to_one :total_item_count,
              read_only: true,
              key: :id,
              class: "Suma::Commerce::Order",
              dataset: proc {
                Suma::Commerce::Order.
                  join(:commerce_checkout_items, {checkout_id: :checkout_id}).
                  where(Sequel[:commerce_orders][:id] => id).
                  select { coalesce(sum(immutable_quantity), 0).as(total_item_count) }.
                  naked
              },
              eager_loader: (lambda do |eo|
                eo[:rows].each { |p| p.associations[:total_item_count] = nil }
                Suma::Commerce::Order.
                  join(:commerce_checkout_items, {checkout_id: :checkout_id}).
                  where(Sequel[:commerce_orders][:id] => eo[:id_map].keys).
                  select_group(Sequel[:commerce_orders][:id].as(:order_id)).
                  select_append { coalesce(sum(immutable_quantity), 0).as(total_item_count) }.
                  naked.
                  all do |t|
                  p = eo[:id_map][t.delete(:order_id)].first
                  p.associations[:total_item_count] = t
                end
              end)

  dataset_module do
    def available_to_claim
      return self.uncanceled.where(
        fulfillment_status: ["fulfilling"],
        checkout: Suma::Commerce::Checkout.where(fulfillment_option: Suma::Commerce::OfferingFulfillmentOption.pickup),
      )
    end

    def ready_for_fulfillment
      return self.where(fulfillment_status: "unfulfilled", order_status: FULFILLABLE_ORDER_STATUSES)
    end

    def canceled
      return self.where(order_status: "canceled")
    end

    def uncanceled
      return self.where(order_status: ["open", "completed"])
    end
  end

  def total_item_count
    # Pick just the 'select' column from the associated object
    return (super || {}).fetch(:total_item_count, 0)
  end

  state_machine :order_status, initial: :open do
    state :open, :completed, :canceled

    event :cancel do
      transition open: :canceled
    end
    after_transition on: :cancel, do: :after_open_order_canceled

    after_transition(&:commit_audit_log)
    after_failure(&:commit_audit_log)
  end

  state_machine :fulfillment_status, initial: :unfulfilled do
    state :unfulfilled, :fulfilling, :fulfilled

    event :begin_fulfillment_on_create do
      transition unfulfilled: :fulfilling, if: :can_begin_fulfilling_on_create?
    end

    event :begin_fulfillment do
      transition unfulfilled: :fulfilling, if: :can_begin_fulfilling?
    end

    event :end_fulfillment do
      transition fulfilling: :fulfilled
    end
    after_transition on: :end_fulfillment, do: :apply_fulfillment_quantity_changes

    event :claim do
      transition fulfilling: :fulfilled, if: :can_claim?
    end
    after_transition on: :claim, do: :apply_fulfillment_quantity_changes

    event :unfulfill do
      transition [:fulfilling, :fulfilled] => :unfulfilled
    end
    after_transition fulfilled: :unfulfilled, do: :reverse_fulfillment_quantity_changes

    after_transition(&:commit_audit_log)
    after_failure(&:commit_audit_log)
  end

  timestamp_accessors(
    [
      [{to: "fulfilling"}, :fulfillment_started_at],
      [{to: "fulfilled"}, :fulfilled_at],
    ],
  )

  def serial = "%04d" % self.id

  def member = self.checkout.cart.member

  # How much was paid for this order is the sum of all book transactions linked to charges.
  # Note that this includes subsidy AND synchronous charges during checkout.
  def paid_amount = self.charges.sum(Money.new(0), &:discounted_subtotal)
  alias paid_cost paid_amount

  # How much of the paid amount was synchronously funded during checkout?
  # Note that there is no book transaction associated from the charge (which are all debits)
  # to the funding transaction (which is a credit)- payments work with ledgers, not linking
  # charges to orders, so we keep track of this additional data via associated_funding_transaction.
  def funded_amount
    return self.charges.map(&:associated_funding_transactions).flatten.sum(Money.new(0), &:amount)
  end
  alias funded_cost funded_amount

  delegate :undiscounted_cost, :customer_cost, :savings, :handling, :taxable_cost, :tax, :total,
           to: :checkout

  def cash_paid
    cash = self.member.payment_account&.cash_ledger
    return self.charges.sum(Money.new(0)) do |ch|
      ch.book_transactions.
          select { |x| x.originating_ledger === cash }.
          sum(Money.new(0), &:amount)
    end
  end

  def noncash_paid = self.paid_cost - self.cash_paid

  def after_open_order_canceled
    return if self.fulfillment_status == "fulfilled"
    self.items_and_product_inventories.each do |ci, inv|
      inv.quantity_pending_fulfillment -= ci.quantity
      inv.save_changes
    end
  end

  def admin_status_label
    return "#{self.order_status} / #{self.fulfillment_status}"
  end

  def rel_admin_link = "/order/#{self.id}"

  def fulfillment_options_for_editing
    return [] unless self.unfulfilled?
    opts = self.checkout.available_fulfillment_options
    opts.prepend(self.checkout.fulfillment_option) unless opts.any? { |opt| opt === self.checkout.fulfillment_option }
    return opts
  end

  def apply_fulfillment_quantity_changes
    self.items_and_product_inventories.each do |ci, inv|
      inv.quantity_on_hand -= ci.quantity if inv.limited_quantity?
      inv.quantity_pending_fulfillment -= ci.quantity
      inv.save_changes
    end
  end

  def reverse_fulfillment_quantity_changes
    self.items_and_product_inventories.each do |ci, inv|
      inv.quantity_on_hand += ci.quantity if inv.limited_quantity?
      inv.quantity_pending_fulfillment += ci.quantity
      inv.save_changes
    end
  end

  protected def items_and_product_inventories
    return self.checkout.items.filter_map do |ci|
      inv = ci.offering_product.product.inventory
      inv ? [ci, inv] : nil
    end
  end

  # Begin fulfilling if the order is in a fulfillable status (ie, don't fulfill canceled orders)
  # and the offering fulfillment time has passed (or there is none).
  def can_begin_fulfilling?(now: Time.now)
    return false unless FULFILLABLE_ORDER_STATUSES.include?(self.order_status)
    offering = self.checkout.cart.offering
    # Untimed offerings can always have their an order start being fulfilled.
    return true unless offering.timed?
    # Otherwise we can only fulfill once fulfillment time has passed.
    return offering.begin_fulfillment_at <= now
  end

  # Orders can begin fulfilling on create if and only if
  # the offering's 'begin fulfillment time' has passed.
  # If offering's begin fulfillment time' is in the future,
  # the order will be caught by the processor.
  # If the offering is untimed (nil begin fulfillment time),
  # orders are only ever fulfilled manually.
  def can_begin_fulfilling_on_create?(now: Time.now)
    offering = self.checkout.cart.offering
    return false unless offering.timed?
    return offering.begin_fulfillment_at <= now
  end

  def can_claim?
    return self.fulfillment_status == "fulfilling" && self.checkout.fulfillment_option.pickup?
  end
end

# Table: commerce_orders
# --------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                 | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at         | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at         | timestamp with time zone |
#  order_status       | text                     | NOT NULL
#  fulfillment_status | text                     | NOT NULL
#  checkout_id        | integer                  | NOT NULL
#  external_id        | text                     | NOT NULL DEFAULT ''::text
# Indexes:
#  commerce_orders_pkey            | PRIMARY KEY btree (id)
#  commerce_orders_checkout_id_key | UNIQUE btree (checkout_id)
# Foreign key constraints:
#  commerce_orders_checkout_id_fkey | (checkout_id) REFERENCES commerce_checkouts(id)
# Referenced By:
#  charges                   | charges_commerce_order_id_fkey          | (commerce_order_id) REFERENCES commerce_orders(id) ON DELETE SET NULL
#  commerce_order_audit_logs | commerce_order_audit_logs_order_id_fkey | (order_id) REFERENCES commerce_orders(id)
# --------------------------------------------------------------------------------------------------------------------------------------------
