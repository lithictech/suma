# frozen_string_literal: true

RSpec.describe "Suma::Commerce::Cart", :db do
  let(:described_class) { Suma::Commerce::Cart }
  let(:context) { Suma::Payment::CalculationContext.new(Time.now) }

  describe "lookup" do
    it "creates a new cart if no carts exist matching criteria" do
      member = Suma::Fixtures.member.create
      offering = Suma::Fixtures.offering.create
      cart1 = described_class.lookup(member:, offering:)
      expect(described_class.lookup(member:, offering:)).to be === cart1
    end
  end

  describe "set_item" do
    let(:member) { Suma::Fixtures.member.create }
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.create }
    let!(:offering_product) { Suma::Fixtures.offering_product(offering:, product:).create }
    let(:cart) { Suma::Fixtures.cart(member:, offering:).create }

    it "adds, updates, and removes a product" do
      cart.set_item(product, 10, timestamp: described_class::IGNORE)
      expect(cart.items).to contain_exactly(have_attributes(product: be === product, quantity: 10))
      cart.set_item(product, 20, timestamp: described_class::IGNORE)
      expect(cart.items).to contain_exactly(have_attributes(product: be === product, quantity: 20))
      cart.set_item(product, 0, timestamp: described_class::IGNORE)
      expect(cart.items).to be_empty
      cart.set_item(product, 0, timestamp: described_class::IGNORE)
      expect(cart.items).to be_empty
    end

    it "errors if the product is not available and is being modified" do
      offering_product.update(closed_at: Time.now)
      expect do
        cart.set_item(product, 10, timestamp: described_class::IGNORE)
      end.to raise_error(described_class::ProductUnavailable)
    end

    it "errors if product is nil" do
      expect do
        cart.set_item(nil, 10, timestamp: described_class::IGNORE)
      end.to raise_error(described_class::ProductUnavailable)
    end

    it "allows removal of an unavailable product" do
      cart.set_item(product, 10, timestamp: described_class::IGNORE)
      offering_product.update(closed_at: Time.now)
      cart.set_item(product, 0, timestamp: described_class::IGNORE)
      expect(cart.items).to be_empty
    end

    it "errors if the given timestamp is after the cart item timestamp" do
      timestamp = nil
      cart.set_item(product, 10, timestamp:)
      expect(cart.items.first).to have_attributes(quantity: 10)
      expect { cart.set_item(product, 20, timestamp:) }.to raise_error(described_class::OutOfOrderUpdate)

      timestamp = 10
      cart.set_item(product, 20, timestamp:)
      expect(cart.items.first).to have_attributes(quantity: 20)
      expect { cart.set_item(product, 0, timestamp:) }.to raise_error(described_class::OutOfOrderUpdate)

      timestamp = 20
      cart.set_item(product, 0, timestamp:)
      expect(cart.items).to be_empty
    end

    it "deletes any associated checkout items" do
      cart.set_item(product, 10, timestamp: 10)
      co = Suma::Fixtures.checkout(cart:).populate_items.create
      expect(co.items).to contain_exactly(have_attributes(cart_item: be === cart.items.first))

      cart.set_item(product, 0, timestamp: 20)
      expect(co.refresh.items).to be_empty
    end
  end

  describe "max_quantity_for" do
    let(:member) { Suma::Fixtures.member.create }
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.with_categories.create }
    let!(:offering_product) { Suma::Fixtures.offering_product(offering:, product:).create }
    let(:cart) { Suma::Fixtures.cart(member:, offering:).create }

    describe "with no quantity limitations" do
      it "returns the default max quantity" do
        expect(cart.max_quantity_for(offering_product)).to eq(12)
      end
    end

    def create_fake_order(cart)
      member = cart.member
      Suma::Fixtures::Members.register_as_stripe_customer(member)
      Suma::Payment.ensure_cash_ledger(member)
      card = Suma::Fixtures.card.member(member).create
      co1 = Suma::Fixtures.checkout(cart:, card:).populate_items.create
      order = Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.not_ready) do
        co1.create_order(cash_charge_amount: co1.items.sum(&:customer_cost), apply_at: Time.now)
      end
      return order
    end

    describe "with a maximum quantity per member on the product" do
      it "returns the quantity value minus the amount the member has ordered already in uncanceled orders" do
        product.inventory!.update(max_quantity_per_member_per_offering: 5)
        expect(cart.refresh.max_quantity_for(offering_product)).to eq(5)

        cart.add_item(product:, quantity: 2, timestamp: 0)
        order = create_fake_order(cart)

        expect(cart.refresh.max_quantity_for(offering_product)).to eq(3)

        order.update(order_status: "canceled")

        expect(cart.refresh.max_quantity_for(offering_product)).to eq(5)
        # Test eager loading does not break/cause an error
        expect(Suma::Commerce::Cart.all.first.max_quantity_for(offering_product)).to eq(5)
      end
    end

    describe "with a maximum number of items cumulative on the offering" do
      it "returns the quantity value minus the total number of items in uncanceled orders" do
        offering.update(max_ordered_items_cumulative: 5)
        expect(cart.refresh.max_quantity_for(offering_product)).to eq(5)

        order = create_fake_order(Suma::Fixtures.cart.with_product(product, 2).create(offering:))

        expect(cart.refresh.max_quantity_for(offering_product.refresh)).to eq(3)

        order.update(order_status: "canceled")

        expect(cart.refresh.max_quantity_for(offering_product.refresh)).to eq(5)
      end
    end

    describe "with a maximum number of items per member on the offering" do
      it "returns the quantity value minus the total number of items in uncanceled orders for the member" do
        offering.update(max_ordered_items_per_member: 50)
        expect(cart.refresh.max_quantity_for(offering_product)).to eq(50)

        # Ignore the order not from the member
        create_fake_order(Suma::Fixtures.cart.with_product(product, 2).create(offering:))
        expect(cart.refresh.max_quantity_for(offering_product.refresh)).to eq(50)

        cart.add_item(product:, quantity: 10, timestamp: 0)
        order = create_fake_order(cart)
        expect(cart.refresh.max_quantity_for(offering_product.refresh)).to eq(40)

        order.update(order_status: "canceled")
        expect(cart.refresh.max_quantity_for(offering_product.refresh)).to eq(50)
      end
    end

    describe "with limited inventory" do
      let(:product) do
        super().inventory!.
          update(limited_quantity: true, quantity_on_hand: 5, quantity_pending_fulfillment: 3).
          product
      end

      it "uses unallocated quantity on hand" do
        expect(cart.refresh.max_quantity_for(offering_product)).to eq(2)
      end
    end

    describe "with offering and inventory limits" do
      it "returns the less available quantity" do
        product.inventory!.update(limited_quantity: true, quantity_on_hand: 6)
        expect(cart.refresh.max_quantity_for(offering_product)).to eq(6)
        offering.update(max_ordered_items_cumulative: 5)
        expect(cart.refresh.max_quantity_for(offering_product)).to eq(5)
      end
    end
  end

  describe "cost_info" do
    it "calculates appropriate product and cart cost based on ledger contributions" do
      cash_vsc = Suma::Vendor::ServiceCategory.cash
      food_vsc = Suma::Fixtures.vendor_service_category(name: "Food", parent: cash_vsc).create
      member = Suma::Fixtures.member.create
      cash_ledger = Suma::Payment.ensure_cash_ledger(member)
      food_ledger = Suma::Fixtures.ledger.member(member).with_categories(food_vsc).create
      offering = Suma::Fixtures.offering.create
      food_product1 = Suma::Fixtures.product.with_categories(food_vsc).create
      food_op1 = Suma::Fixtures.offering_product(product: food_product1, offering:).costing("$400", "$500").create

      cart = Suma::Fixtures.cart(offering:, member:).
        with_product(food_product1, 2).
        create

      ci = cart.cost_info(context)
      expect(ci.product_noncash_ledger_contribution_amount(food_op1)).to cost("$0")
      expect(ci.noncash_ledger_contribution_amount).to cost("$0")
      expect(ci.cash_cost).to cost("$800")
      Suma::Fixtures.book_transaction.to(food_ledger).create(amount: money("$13"))
      cart.refresh
      expect(ci.product_noncash_ledger_contribution_amount(food_op1)).to cost("$13")
      expect(ci.noncash_ledger_contribution_amount).to cost("$13")
      expect(ci.cash_cost).to cost("$787")
    end
  end

  describe "Suma::Commerce::CartItem" do
    let(:described_class) { Suma::Commerce::CartItem }

    let(:member) { Suma::Fixtures.member.create }
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.create }

    it "has an association to an offering_product" do
      cart = Suma::Fixtures.cart(member:, offering:).with_product(product).create
      item = cart.items.first
      expect(item).to have_attributes(offering_product: nil)
      op = Suma::Fixtures.offering_product(offering:, product:).create
      expect(item.refresh).to have_attributes(offering_product: be === op)
      expect(described_class.all.first).to have_attributes(offering_product: be === op) # eager loading
      expect(described_class[item.id]).to have_attributes(offering_product: be === op) # non-eager loading
    end
  end

  describe "create_checkout" do
    let(:member) { Suma::Fixtures.member.registered_as_stripe_customer.create }
    let(:offering) { Suma::Fixtures.offering.create(max_ordered_items_cumulative: 20, max_ordered_items_per_member: 5) }
    let!(:fulfillment) { Suma::Fixtures.offering_fulfillment_option(offering:).create }
    let(:product) { Suma::Fixtures.product.with_categories.create }
    let!(:offering_product) { Suma::Fixtures.offering_product(product:, offering:).create }
    let!(:cart) { Suma::Fixtures.cart(offering:, member:).with_product(product, 2).create }

    def create_checkout(cart_: cart)
      context = Suma::Payment::CalculationContext.new(Time.now)
      cart_.create_checkout(context)
    end

    it "soft deletes any pending checkouts" do
      other_member_checkout = Suma::Fixtures.checkout(cart: Suma::Fixtures.cart(member:).create).create
      completed_checkout = Suma::Fixtures.checkout(cart:).completed.create

      create_checkout

      expect(other_member_checkout.refresh).to be_soft_deleted
      expect(completed_checkout.refresh).to_not be_soft_deleted
    end

    it "starts a checkout with the only offering fulfillment option available" do
      expect(create_checkout.fulfillment_option).to eq(offering.fulfillment_options.first)
    end

    it "starts a checkout with fulfillment option from a previously editable checkout" do
      # add multiple options to offering to then set the existing checkout option
      Suma::Fixtures.offering_fulfillment_option(offering:).create
      noneditable_checkout = Suma::Fixtures.checkout(cart:).with_fulfillment_option(fulfillment).complete.create
      existing_editable_checkout = Suma::Fixtures.checkout(cart:).with_fulfillment_option(fulfillment).create

      expect(create_checkout.fulfillment_option).to eq(existing_editable_checkout.fulfillment_option)
    end

    it "raises if there are no items in the cart" do
      cart.items.first.delete
      expect { create_checkout }.to raise_error(described_class::EmptyCart)
    end

    it "raises if the available inventory is insufficient for what is in the cart" do
      offering.update(max_ordered_items_per_member: 1)
      expect { create_checkout }.to raise_error(Suma::Commerce::Checkout::MaxQuantityExceeded)
    end

    it "raises if any product is no longer available due to deleted offering" do
      offering_product.delete
      expect { create_checkout }.to raise_error(described_class::ProductUnavailable)
    end

    it "raises if any product is no longer available due to closed offering" do
      offering.update(period_end: 1.day.ago)
      expect { create_checkout }.to raise_error(described_class::ProductUnavailable)
    end
  end
end
