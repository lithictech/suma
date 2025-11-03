# frozen_string_literal: true

require "suma/commerce"
require "suma/charge/charger"
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
  one_to_many :items, class: "Suma::Commerce::CheckoutItem", order: order_desc
  one_to_one :order, class: "Suma::Commerce::Order"
  many_to_one :fulfillment_option, class: "Suma::Commerce::OfferingFulfillmentOption"

  def editable? = !self.soft_deleted? && !self.completed?
  def completed? = !self.completed_at.nil?
  def available_fulfillment_options = self.cart.offering.fulfillment_options.reject(&:soft_deleted?)
  def available_payment_instruments = self.cart.member.public_payment_instruments.select(&:usable_for_funding?)
  def unavailable_payment_instruments = self.cart.member.public_payment_instruments.reject(&:usable_for_funding?)

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
        raise TypeError, "Unhandled payment instrument: #{pi.inspect}"
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
  def total = self.taxable_cost + self.tax

  # Cost and related information about the checkout.
  # This requires calculating what will be owed/charged at checkout.
  # This is always done on the predicted contributions,
  # since that's generally what we care about at this stage.
  #
  # If, during completing checkout (+create_order+),
  # the predicted and actual results do not match,
  # completing the checkout will fail.
  class CostInfo
    def initialize(checkout, apply_at)
      @checkout = checkout
      @apply_at = apply_at
      @contributions = checkout.predicted_charge_contributions(apply_at:)
    end

    # How much additional cash will be charged?
    # @return [Money]
    def chargeable_total = @contributions.cash.outstanding

    def requires_payment_instrument? = !self.chargeable_total.zero?

    def checkout_prohibited_reason
      return :member_unverified if @checkout.cart.member.read_only_reason === "read_only_unverified"
      return :offering_products_unavailable if @checkout.cart.items.none? { |ci| ci.available_at?(@apply_at) }
      return :requires_payment_instrument if self.requires_payment_instrument? && !@checkout.payment_instrument
      return :not_editable unless @checkout.editable?
      return nil
    end

    # Return charge contributions that:
    # - Are already on ledgers (cash and non-cash).
    # - Non-cash contributions that are added by triggers
    def existing_funds_available
      contribs = @contributions.all.to_a
      # The cash ledger (always first from the #all result) should have the contribution amount
      # set to what is from the existing balance. The outstanding value goes into chargeable_total.
      # CASH_CONTRIB: The 'only show existing funds on cash ledger' logic needs tests once it's supported.
      contribs[0] = contribs[0].dup(amount: contribs[0].from_balance)
      # Only include contributions that have an amount.
      return contribs.select(&:amount?)
    end
  end

  def cost_info(at:) = CostInfo.new(self, at)

  # @return [Suma::Payment::ChargeContribution::Collection]
  def predicted_charge_contributions(apply_at:)
    return Suma::Commerce::PricedItem.ideal_ledger_charge_contributions(
      Suma::Payment::CalculationContext.new(apply_at),
      self.cart.member.payment_account!,
      self.items,
    )
  end

  # @return [Suma::Payment::ChargeContribution::Collection]
  def actual_charge_contributions(apply_at:)
    return Suma::Commerce::PricedItem.actual_ledger_charge_contributions(
      Suma::Payment::CalculationContext.new(apply_at),
      self.cart.member.payment_account!,
      self.items,
    )
  end

  # Create an order from this checkout.
  # We pass in the time, and expected charge amount.
  # The time is used for a new calculation context, using the actual state of the ledger.
  # The cash charge is passed in, rather than calculated, so we can confirm the amount the user expects
  # is what is actually charged (ie, avoids race conditions or out-of-date UI).
  # If too little is charged, a balance will be owed and this method will error.
  # If too much is charged, a balance will be left on the cash ledger, and this method will error
  # (this may change when we support non-zero cash ledger balances).
  #
  # @param apply_at [Time]
  # @param cash_charge_amount [Money]
  def create_order(apply_at:, cash_charge_amount:)
    self.db.transaction do
      # Locking the cart makes sure we don't allow the user to over-purchase for an offering
      self.cart.lock!
      # Locking the checkout ensures we don't process it multiple times as a race
      self.lock!
      # This isn't ideal- it'd be better
      if (prohibition_reason = self.cost_info(at: apply_at).checkout_prohibited_reason)
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

      charger = Charger.new(
        order:,
        expected_charge_amount: cash_charge_amount,
        member: self.cart.member,
        apply_at:,
        undiscounted_subtotal: self.undiscounted_cost + self.handling + self.tax,
        charge_kwargs: {commerce_order: order},
      )

      charge = charger.charge
      # Instead of an itemized charge receipt, just add each transaction as an item.
      # We will use the order itself to create an itemized receipt.
      charge.contributing_book_transactions.each do |x|
        charge.add_line_item(amount: x.amount, memo: x.memo)
      end
      return order
    end
  end

  class Charger < Suma::Charge::Charger
    def initialize(order:, expected_charge_amount:, **)
      @order = order
      @expected_charge_amount = expected_charge_amount
      super(**)
    end

    def predicted_charge_contributions = @order.checkout.predicted_charge_contributions(apply_at: self.apply_at)
    def actual_charge_contributions = @order.checkout.actual_charge_contributions(apply_at: self.apply_at)

    def verify_predicted_contribution(contrib)
      return unless contrib.cash.outstanding != @expected_charge_amount
      msg = "Checkout[#{@order.id}] desired charge of #{@expected_charge_amount.format} and calculated charge " \
            "of #{contrib.cash.outstanding.format} differ, please refresh and try again."
      raise Prohibited.new(msg, reason: :charge_amount_mismatch)
    end

    def contribution_memo
      return Suma::TranslatedText.create(
        en: "Suma Order %04d - %s" % [@order.id, @order.checkout.cart.offering.description.en],
        es: "Suma Pedido %04d - %s" % [@order.id, @order.checkout.cart.offering.description.es],
      )
    end

    def start_funding_transaction(amount:)
      return Suma::Payment::FundingTransaction.start_new(
        self.member.payment_account,
        amount:,
        instrument: @order.checkout.payment_instrument,
        # Once we have asynchronous instruments (bank accounts, etc.),
        # we can set this to true and figure out how to handle later failures.
        collect: :must,
      )
    end
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
#  fulfillment_option_id   | integer                  |
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
