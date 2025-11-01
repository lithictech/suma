# frozen_string_literal: true

require "suma/behaviors"

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

  describe "fulfillment_options_for_editing" do
    let(:offering) { Suma::Fixtures.offering.create }
    let(:order) do
      checkout = Suma::Fixtures.checkout(cart: Suma::Fixtures.cart(offering:).create).completed.create
      Suma::Fixtures.order(checkout:).create
    end

    it "shows checkout options on an unfulfilled order" do
      expect(order.fulfillment_options_for_editing).to have_same_ids_as(*offering.fulfillment_options)
    end

    it "excludes nil checkout option" do
      order.checkout.update(fulfillment_option: nil)
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

  describe "fulfillment_option_editable?" do
    let(:offering) { Suma::Fixtures.offering.create }
    let(:order) do
      checkout = Suma::Fixtures.checkout(cart: Suma::Fixtures.cart(offering:).create).completed.create
      Suma::Fixtures.order(checkout:).create
    end

    it "returns false if there are no options in the offering" do
      order.checkout.update(fulfillment_option: nil)
      order.checkout.cart.offering.fulfillment_options.each(&:soft_delete)
      expect(order).to_not be_fulfillment_option_editable
    end

    it "returns true when no option is chosen and theres at least one available" do
      order.checkout.update(fulfillment_option: nil)
      expect(order).to be_fulfillment_option_editable
    end

    it "returns true when option is chosen and there are more than one available" do
      expect(order).to_not be_fulfillment_option_editable
      another_option = Suma::Fixtures.offering_fulfillment_option.create(offering:)
      expect(order).to be_fulfillment_option_editable
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

    it "can be claimed if the order is fulfilling and there is no fulfillment option" do
      order.update(fulfillment_status: "fulfilled")
      expect(order).to_not be_can_claim

      order.fulfillment_status = "unfulfilled"
      expect(order).to_not be_can_claim

      order.update(fulfillment_status: "fulfilling")
      expect(order).to be_can_claim

      order.refresh
      order.checkout.fulfillment_option = nil
      expect(order).to be_can_claim
    end

    it "can be claimed if the order is fulfilling and there is a fulfillment option of type pickup" do
      order.update(fulfillment_status: "fulfilling")
      order.checkout.fulfillment_option.update(type: "pickup")
      expect(order).to be_can_claim

      order.refresh
      order.checkout.fulfillment_option.type = "delivery"
      expect(order).to_not be_can_claim
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

  describe "OrderAuditLog" do
    it_behaves_like "an audit log", Suma::Commerce::OrderAuditLog, :order do
      let(:parent) { Suma::Fixtures.order.create }
    end
  end
end
