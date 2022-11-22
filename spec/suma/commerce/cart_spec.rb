# frozen_string_literal: true

RSpec.describe "Suma::Commerce::Cart", :db do
  let(:described_class) { Suma::Commerce::Cart }

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
    let(:product) { Suma::Fixtures.product.create }
    let!(:offering_product) { Suma::Fixtures.offering_product(offering:, product:).create }
    let(:cart) { Suma::Fixtures.cart(member:, offering:).create }

    it "returns 12 if the max quantity values are nil" do
      expect(cart.max_quantity_for(offering_product)).to eq(12)
    end

    describe "without any preexisting data" do
      it "returns the lesser of max quantity for order and offering" do
        product.max_quantity_per_order = 4
        expect(cart.max_quantity_for(offering_product)).to eq(4)
        product.max_quantity_per_offering = 5
        expect(cart.max_quantity_for(offering_product)).to eq(4)
        product.max_quantity_per_order = nil
        expect(cart.max_quantity_for(offering_product)).to eq(5)
      end
    end

    describe "with previous orders" do
      let(:card) { Suma::Fixtures.card.member(member).create }
      let(:product) { super().update(max_quantity_per_order: 5) }
      before(:each) do
        Suma::Fixtures::Members.register_as_stripe_customer(member)
        Suma::Payment.ensure_cash_ledger(member)
      end

      it "counts previous non-canceled orders against the max for an offering" do
        expect(cart.max_quantity_for(offering_product)).to eq(5)

        cart.add_item(product:, quantity: 2, timestamp: 0)
        co1 = Suma::Fixtures.checkout(cart:, card:).populate_items.create
        order = Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.not_ready) do
          co1.create_order
        end

        expect(cart.refresh.max_quantity_for(offering_product)).to eq(3)

        order.update(order_status: "canceled")

        expect(cart.refresh.max_quantity_for(offering_product)).to eq(5)
        # Test eager loading
        expect(Suma::Commerce::Cart.all.first.max_quantity_for(offering_product)).to eq(5)
      end
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
end
