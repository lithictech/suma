# frozen_string_literal: true

RSpec.describe "Suma::Commerce::Order", :db do
  let(:described_class) { Suma::Commerce::Order }

  describe "associations" do
    it "can count total items" do
      o = Suma::Fixtures.order.as_purchased_by(Suma::Fixtures.member.create).create
      expect(o.refresh.total_item_count).to eq(1)
      o.checkout.items.first.update(immutable_quantity: 2)
      expect(o.refresh.total_item_count).to eq(2)
      expect(Suma::Commerce::Order.where(id: o.id).all.first.total_item_count).to eq(2)
    end
  end

  it "can make a serial number" do
    o = Suma::Fixtures.order.create
    o.id = 12
    expect(o.serial).to eq("0012")
  end

  it "knows how much was paid" do
    charge = Suma::Fixtures.charge.create
    bx = Suma::Fixtures.book_transaction.create(amount: money("$12.50"))
    charge.add_book_transaction(bx)
    o = Suma::Fixtures.order.create
    expect(o.paid_amount).to cost("$0")
    o.add_charge(charge)
    expect(o.paid_amount).to cost("$12.50")
  end

  it "knows how much was synchronously funded" do
    charge = Suma::Fixtures.charge.create
    fx = Suma::Fixtures.funding_transaction.with_fake_strategy.create(amount: money("$12.50"))
    charge.add_associated_funding_transaction(fx)
    o = Suma::Fixtures.order.create
    expect(o.funded_amount).to cost("$0")
    o.add_charge(charge)
    expect(o.funded_amount).to cost("$12.50")
  end

  it "knows how much was paid in cash and non-cash" do
    charge = Suma::Fixtures.charge.create
    cash = Suma::Payment.ensure_cash_ledger(charge.member)
    bxcash = Suma::Fixtures.book_transaction.from(cash).create(amount: money("$12.50"))
    bxnoncash = Suma::Fixtures.book_transaction.from({account: cash.account}).create(amount: money("$5"))
    charge.add_book_transaction(bxcash)
    charge.add_book_transaction(bxnoncash)
    o = Suma::Fixtures.order.as_purchased_by(charge.member).create
    o.add_charge(charge)
    expect(o.cash_paid).to cost("$12.50")
    expect(o.noncash_paid).to cost("$5")
  end

  describe "fulfillment_options_for_editing" do
    let(:offering) { Suma::Fixtures.offering.create }
    let(:order) do
      checkout = Suma::Fixtures.checkout(cart: Suma::Fixtures.cart(offering:).create).completed.create
      Suma::Fixtures.order(checkout:).create
    end

    it "shows checkout options on an unfulfilled order" do
      expect(order.fulfillment_options_for_editing).to have_same_ids_as(*offering.fulfillment_options)
    end

    it "is empty for a non-unfulfilled order" do
      order.fulfillment_status = "fulfilling"
      expect(order.fulfillment_options_for_editing).to be_empty
    end

    it "includes the current option even if it is deleted" do
      order.checkout.fulfillment_option.soft_delete
      expect(order.fulfillment_options_for_editing).to have_same_ids_as(*offering.fulfillment_options)
    end
  end

  describe "fulfillment state machine" do
    let(:limited_product) { Suma::Fixtures.product.limited_quantity(4, 2).create }
    let(:unlimited_product) { Suma::Fixtures.product.create }
    let(:cart) do
      Suma::Fixtures.cart.
        with_offering_of_product(limited_product, 1).
        with_offering_of_product(unlimited_product, 1).
        create
    end
    let(:checkout) { Suma::Fixtures.checkout(cart:).with_payment_instrument.populate_items.completed.create }
    let(:order) { Suma::Fixtures.order(checkout:).create }

    it "removes from onhand and quantity pending fulfillment when fulfillment completes" do
      expect(order).to transition_on(:begin_fulfillment).to("fulfilling")
      expect(limited_product.inventory.refresh).to have_attributes(
        quantity_on_hand: 4, quantity_pending_fulfillment: 2,
      )

      expect(order).to transition_on(:end_fulfillment).to("fulfilled")
      expect(limited_product.inventory.refresh).to have_attributes(
        quantity_on_hand: 3, quantity_pending_fulfillment: 1,
      )
      expect(unlimited_product.refresh.inventory).to be_nil

      # Ensure quantity not removed if there's no transition
      expect(order).to not_transition_on(:end_fulfillment)
      expect(limited_product.inventory.refresh).to have_attributes(
        quantity_on_hand: 3, quantity_pending_fulfillment: 1,
      )
    end

    it "adds to quantity pending fulfillment and quantity on hand when unfulfilling from fulfilled" do
      order.fulfillment_status = "fulfilled"
      expect(order).to transition_on(:unfulfill).to("unfulfilled")
      expect(limited_product.inventory.refresh).to have_attributes(
        quantity_on_hand: 5, quantity_pending_fulfillment: 3,
      )
      expect(unlimited_product.inventory).to be_nil

      order.fulfillment_status = "fulfilling"
      expect(order).to transition_on(:unfulfill).to("unfulfilled")
      expect(limited_product.inventory.refresh).to have_attributes(
        quantity_on_hand: 5, quantity_pending_fulfillment: 3,
      ) # Assert has no changed, since the quantity modification has not been applied yet
    end

    it "can claim claimable orders" do
      expect(order).to not_transition_on(:claim)
      expect(order).to transition_on(:begin_fulfillment).to("fulfilling")
      expect(order).to transition_on(:claim).to("fulfilled")
    end

    it "can only be claimed if the fulfillment exists, is of type pickup and the order is fulfilling" do
      order.update(fulfillment_status: "fulfilling")
      order.checkout.fulfillment_option.update(type: "pickup")
      expect(order).to be_can_claim

      order.fulfillment_status = "unfulfilled"
      expect(order).to_not be_can_claim

      order.refresh
      order.checkout.fulfillment_option.type = "delivery"
      expect(order).to_not be_can_claim

      order.refresh
      order.checkout.fulfillment_option = nil
      expect(order).to_not be_can_claim

      order.refresh
      expect(order).to be_can_claim
    end

    it "can begin fulfillment of orders with a past or nil fulfillment time and valid status" do
      offering = checkout.cart.offering
      order.update(order_status: "open")

      # Check the time validator
      offering.update(begin_fulfillment_at: 5.minutes.from_now)
      expect(order).to not_transition_on(:begin_fulfillment)

      offering.update(begin_fulfillment_at: nil)
      expect(order).to transition_on(:begin_fulfillment).to("fulfilling")
      order.update(fulfillment_status: "unfulfilled")

      offering.update(begin_fulfillment_at: 5.minutes.ago)
      expect(order).to transition_on(:begin_fulfillment).to("fulfilling")
      order.update(fulfillment_status: "unfulfilled")

      # Check that canceled orders can't be fulfilled
      order.update(order_status: "canceled")
      expect(order).to not_transition_on(:begin_fulfillment)
    end
  end

  describe "order status state machine" do
    let(:limited_product) { Suma::Fixtures.product.limited_quantity(4, 2).create }
    let(:unlimited_product) { Suma::Fixtures.product.create }
    let(:cart) do
      Suma::Fixtures.cart.
        with_offering_of_product(limited_product, 1).
        with_offering_of_product(unlimited_product, 1).
        create
    end
    let(:checkout) { Suma::Fixtures.checkout(cart:).with_payment_instrument.populate_items.completed.create }
    let(:order) { Suma::Fixtures.order(checkout:).create }

    it "removes from quantity pending fulfillment when canceling an open, not-fulfilled order" do
      expect(order).to have_attributes(order_status: "open", fulfillment_status: "unfulfilled")
      expect(order).to transition_on(:cancel).to("canceled")
      expect(limited_product.inventory.refresh).to have_attributes(
        quantity_on_hand: 4, quantity_pending_fulfillment: 1,
      )
    end

    it "does not modify quantity when canceling a fulfilled order" do
      # In reality if the order is in the 'fulfilled' status we already dealt with the quantity changes,
      # so this should noop.
      order.fulfillment_status = "fulfilled"
      expect(order).to transition_on(:cancel).to("canceled")
      expect(limited_product.inventory.refresh).to have_attributes(
        quantity_on_hand: 4, quantity_pending_fulfillment: 2,
      )
    end
  end
end
