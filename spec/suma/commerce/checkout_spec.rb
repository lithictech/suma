# frozen_string_literal: true

RSpec.describe "Suma::Commerce::Checkout", :db do
  let(:described_class) { Suma::Commerce::Checkout }

  describe "create_order" do
    let(:member) { Suma::Fixtures.member.create }
    let(:offering) { Suma::Fixtures.offering.create }
    let!(:fulfillment) { Suma::Fixtures.offering_fulfillment_option(offering:).create }
    let(:product) { Suma::Fixtures.product.create }
    let!(:offering_product) { Suma::Fixtures.offering_product(product:, offering:).create }
    let(:cart) { Suma::Fixtures.cart(offering:, member:).with_product(product, 2).create }
    let(:card) { Suma::Fixtures.card.member(member).create }
    let(:checkout) { Suma::Fixtures.checkout(cart:, card:).populate_items.create }

    it "errors if the checkout isn't editable" do
      checkout.soft_delete
      expect { checkout.create_order }.to raise_error(described_class::Uneditable)
    end

    it "creates the order from the checkout" do
      order = checkout.create_order
      expect(order).to be_a(Suma::Commerce::Order)
      expect(checkout).to be_completed
      expect(checkout.card).to be_soft_deleted
    end

    it "deletes the cart items, and copies their quantity to the checkout items" do
      checkout.create_order
      expect(checkout.cart.items).to be_empty
      expect(checkout.items.first).to have_attributes(quantity: 2, cart_item: nil)
    end

    it "does not delete the payment instrument if it is being saved" do
      checkout.update(save_payment_instrument: true)
      checkout.create_order
      expect(checkout.card).to_not be_soft_deleted
    end
  end
end
