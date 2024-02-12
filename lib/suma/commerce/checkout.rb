# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::Checkout < Suma::Postgres::Model(:commerce_checkouts)
  CONFIRMATION_EXPOSURE_CUTOFF = 2.days

  class Prohibited < StandardError
    attr_reader :reason

    def initialize(message, reason:)
      @reason = reason
      super(message)
    end
  end

  class MaxQuantityExceeded < StandardError; end

  plugin :timestamps
  plugin :soft_deletes

  many_to_one :cart, class: "Suma::Commerce::Cart"
  many_to_one :card, class: "Suma::Payment::Card"
  many_to_one :bank_account, class: "Suma::Payment::BankAccount"
  one_to_many :items, class: "Suma::Commerce::CheckoutItem"
  one_to_one :order, class: "Suma::Commerce::Order"
  many_to_one :fulfillment_option, class: "Suma::Commerce::OfferingFulfillmentOption"

  def editable? = !self.soft_deleted? && !self.completed?
  def completed? = !self.completed_at.nil?
  def available_fulfillment_options = self.cart.offering.fulfillment_options.reject(&:soft_deleted?)
  def available_payment_instruments = self.cart.member.usable_payment_instruments

  def expose_for_confirmation?(t=Time.now)
    cutoff = t - CONFIRMATION_EXPOSURE_CUTOFF
    return self.created_at > cutoff
  end

  def complete(t=Time.now)
    self.completed_at = t
    return self
  end

  def payment_instrument
    return [self.bank_account, self.card].compact.first
  end

  def payment_instrument=(pi)
    case pi
      when nil
        self.bank_account = nil
        self.card = nil
      when Suma::Payment::BankAccount
        self.bank_account = pi
        self.card = nil
      when Suma::Payment::Card
        self.bank_account = nil
        self.card = pi
      else
        raise "Unhandled payment instrument: #{pi.inspect}"
    end
  end

  # Subtotal of all items, without any discounts.
  # @return [Money]
  def undiscounted_cost = self.items.sum(Money.new(0), &:undiscounted_cost)

  # Subtotal of all items with their discounts.
  # @return [Money]
  def customer_cost = self.items.sum(Money.new(0), &:customer_cost)

  # Difference between customer and undiscounted cost.
  # @return [Money]
  def savings = self.items.sum(Money.new(0), &:savings)

  # Service fee for this order.
  # @return [Money]
  def handling = Money.new(0)

  # Tax can be charged on the subtotal and handling.
  # @return [Money]
  def taxable_cost = self.handling + self.customer_cost

  # Total tax to collect.
  # @return [Money]
  def tax = Money.new(0)

  # Subtotal, handling, and tax make up the total cost for the order.
  # @return [Money]
  def total = self.customer_cost + self.handling

  # Nonzero contributions made by existing customer ledgers against the order totals.
  # @return [Enumerable<Suma::Payment::ChargeContribution]
  def usable_ledger_contributions
    return self.ledger_charge_contributions(now: Time.now).debitable
  end

  # Chargeable total is the total, minus the contributions from customer ledgers.
  # @return [Money]
  def chargeable_total
    total = self.total
    contribs = self.usable_ledger_contributions
    paid = contribs.sum(Money.new(0), &:amount)
    return total - paid
  end

  def chargeable_amount? = !self.chargeable_total.zero?

  def requires_payment_instrument?
    return self.chargeable_amount?
  end

  def checkout_prohibited_reason(at)
    return :offering_products_unavailable if self.cart.items.select { |ci| ci.available_at?(at) }.empty?
    return :requires_payment_instrument if self.requires_payment_instrument? && !self.payment_instrument
    return :not_editable unless self.editable?
    return nil
  end

  def create_order
    self.db.transaction do
      # Locking the card makes sure we don't allow the user to over-purchase for an offering
      self.cart.lock!
      # Locking the checkout ensures we don't process it multiple times as a race
      self.lock!
      now = Time.now
      if (prohibition_reason = self.checkout_prohibited_reason(now))
        raise Prohibited.new(
          "Checkout[#{self.id}] cannot be checked out: #{prohibition_reason}",
          reason: prohibition_reason,
        )
      end
      self.check_and_update_product_inventories
      order = Suma::Commerce::Order.create(checkout: self)
      order.save_changes if order.begin_fulfillment_on_create
      self.freeze_items
      self.cart.items_dataset.delete
      self.cart.associations.delete(:items)
      self.complete.save_changes

      # Record the charge for the full, undiscounted amount.
      charge = Suma::Charge.create(
        member: self.cart.member,
        commerce_order: order,
        undiscounted_subtotal: self.undiscounted_cost + self.handling + self.tax,
      )

      # We have some real possible debits, and possibly a remainder we also need to debit.
      contrib_collection = self.ledger_charge_contributions(now:)
      if contrib_collection.remainder?
        # We'll put the remainder into the cash ledger.
        # If we are already debit the cash ledger, add the remainder to it.
        # This will cause a negative balance (since the current contribution can only be up to its balance).
        contrib_collection.cash.amount += contrib_collection.remainder.amount
      end

      # Create ledger debits for all positive contributions. This MAY bring our balance negative.
      book_xactions = self.cart.member.payment_account.debit_contributions(
        contrib_collection.debitable,
        memo: Suma::TranslatedText.create(
          en: "Suma Order %04d - %s" % [order.id, self.cart.offering.description.en],
          es: "Suma Pedido %04d - %s" % [order.id, self.cart.offering.description.es],
        ),
      )
      book_xactions.each { |x| charge.add_book_transaction(x) }

      # If there are any remainder contributions, we need to fund them against the cash ledger.
      if contrib_collection.remainder?
        funding = Suma::Payment::FundingTransaction.start_and_transfer(
          self.card.member,
          amount: contrib_collection.remainder.amount,
          instrument: self.payment_instrument,
          apply_at: now,
        )
        charge.add_associated_funding_transaction(funding)
      end

      # Delete this at the end, after it's charged.
      self.payment_instrument.soft_delete if self.payment_instrument && !self.save_payment_instrument

      return order
    end
  end

  def ledger_charge_contributions(now:)
    return Suma::Commerce::Checkout.ledger_charge_contributions(
      payment_account: self.cart.member.payment_account!,
      priced_items: self.items,
      now:,
    )
  end

  # Return contributions from each ledger that can be used for paying for the order.
  # NOTE: Right now this is only product contributions; when we support tax and handling,
  # we'll need to modify this routine to factor those into the right (cash?) ledger.
  #
  # @param payment_account [Suma::Payment::Account]
  # @param priced_items [Array<Suma::Commerce::PricedItem>]
  # @param now [Time]
  # @return [Suma::Payment::ChargeContribution::Collection]
  def self.ledger_charge_contributions(payment_account:, priced_items:, now:)
    ctx = Suma::Payment::CalculationContext.new
    collections = priced_items.map do |item|
      coll = payment_account.find_chargeable_ledgers(
        item.offering_product.product,
        item.customer_cost,
        now:,
        calculation_context: ctx,
      )
      ctx.apply_many(*coll.debitable)
      coll
    end
    consolidated_contributions = Suma::Payment::ChargeContribution::Collection.consolidate(collections)
    return consolidated_contributions
  end

  protected def check_and_update_product_inventories
    # Lock all inventories so we can 1) check quantity on limited quantity products,
    # and 2) update pending fulfillment amounts.
    inventories = self.items.map { |it| it.cart_item.product.inventory! }
    inventories.each(&:lock!)
    self.items.each do |item|
      product = item.cart_item.product
      quantity = item.cart_item.quantity
      max_available = self.cart.max_quantity_for(item.offering_product)
      raise MaxQuantityExceeded, "product #{product.name.en} quantity #{quantity} > max of #{max_available}" if
        quantity > max_available
      # Always keep track of what is pending
      product.inventory.quantity_pending_fulfillment += quantity
    end
    inventories.each(&:save_changes)
  end

  protected def freeze_items
    self.items.each do |item|
      item.set(immutable_quantity: item.cart_item.quantity, cart_item: nil)
    end
    self.db.from(:commerce_checkout_items, :commerce_cart_items).
      # See https://github.com/jeremyevans/sequel/discussions/1967
      where(checkout_id: self.id, Sequel[:commerce_cart_items][:id] => Sequel[:commerce_checkout_items][:cart_item_id]).
      update(cart_item_id: nil, immutable_quantity: Sequel[:commerce_cart_items][:quantity])
  end

  def after_soft_delete
    self.freeze_items
  end
end

# Table: commerce_checkouts
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                      | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at              | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at              | timestamp with time zone |
#  soft_deleted_at         | timestamp with time zone |
#  completed_at            | timestamp with time zone |
#  cart_id                 | integer                  | NOT NULL
#  bank_account_id         | integer                  |
#  card_id                 | integer                  |
#  save_payment_instrument | boolean                  | NOT NULL DEFAULT false
#  fulfillment_option_id   | integer                  | NOT NULL
# Indexes:
#  commerce_checkouts_pkey          | PRIMARY KEY btree (id)
#  commerce_checkouts_cart_id_index | UNIQUE btree (cart_id) WHERE completed_at IS NULL AND soft_deleted_at IS NULL
# Check constraints:
#  unambiguous_payment_instrument | (bank_account_id IS NOT NULL AND card_id IS NULL OR bank_account_id IS NULL AND card_id IS NOT NULL OR bank_account_id IS NULL AND card_id IS NULL)
# Foreign key constraints:
#  commerce_checkouts_bank_account_id_fkey       | (bank_account_id) REFERENCES payment_bank_accounts(id)
#  commerce_checkouts_card_id_fkey               | (card_id) REFERENCES payment_cards(id)
#  commerce_checkouts_cart_id_fkey               | (cart_id) REFERENCES commerce_carts(id)
#  commerce_checkouts_fulfillment_option_id_fkey | (fulfillment_option_id) REFERENCES commerce_offering_fulfillment_options(id)
# Referenced By:
#  commerce_checkout_items | commerce_checkout_items_checkout_id_fkey | (checkout_id) REFERENCES commerce_checkouts(id) ON DELETE CASCADE
#  commerce_orders         | commerce_orders_checkout_id_fkey         | (checkout_id) REFERENCES commerce_checkouts(id)
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
