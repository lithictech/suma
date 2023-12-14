# frozen_string_literal: true

require "suma/api/commerce"

RSpec.describe Suma::API::Commerce, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.with_cash_ledger.create }

  before(:each) do
    login_as(member)
  end

  describe "GET /v1/commerce/offerings" do
    it "returns only available offerings" do
      offering1 = Suma::Fixtures.offering.closed.create
      offering2 = Suma::Fixtures.offering.create

      get "/v1/commerce/offerings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(
          include(id: offering2.id),
        ),
      )
    end

    it "401s if not authed" do
      logout
      get "/v1/commerce/offerings"
      expect(last_response).to have_status(401)
    end
  end

  describe "GET /v1/commerce/offerings/:id" do
    it "returns only available offering products" do
      offering = Suma::Fixtures.offering.create
      product = Suma::Fixtures.product.create
      op1 = Suma::Fixtures.offering_product.create(offering:, product:)
      op2 = Suma::Fixtures.offering_product.closed.create(offering:, product:)

      get "/v1/commerce/offerings/#{offering.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(
          include(product_id: op1.product_id),
        ),
      )
    end

    it "returns details about the offering and the member cart" do
      offering = Suma::Fixtures.offering.create
      op = Suma::Fixtures.offering_product(offering:).create
      op = Suma::Fixtures.offering_product(offering:).product(vendor: op.product.vendor).create

      get "/v1/commerce/offerings/#{offering.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        offering: include(id: offering.id, description: offering.description.en),
        cart: include(items: []),
        vendors: contain_exactly(include(id: op.product.vendor.id)),
      )
    end

    it "401s if not authed" do
      logout
      offering = Suma::Fixtures.offering.create
      get "/v1/commerce/offerings/#{offering.id}"
      expect(last_response).to have_status(401)
    end
  end

  describe "PUT /v1/commerce/offerings/:id/cart/item" do
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.create }
    let!(:offering_product) { Suma::Fixtures.offering_product.create(offering:, product:) }

    it "adds a product (uses Cart#set_item)" do
      put "/v1/commerce/offerings/#{offering.id}/cart/item", product_id: product.id, quantity: 2

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(include(product_id: product.id, quantity: 2)),
      )
    end

    it "ignores the change and returns the existing cart if for out of order updates" do
      cart = Suma::Fixtures.cart(offering:, member:).with_product(product, 10, timestamp: 2).create

      put "/v1/commerce/offerings/#{offering.id}/cart/item", product_id: product.id, quantity: 2, timestamp: 1

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(include(product_id: product.id, quantity: 10)),
      )
    end

    it "returns a 409 for product unavailable" do
      offering_product.delete

      put "/v1/commerce/offerings/#{offering.id}/cart/item", product_id: product.id, quantity: 2, timestamp: 1

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(code: "product_unavailable"))
    end
  end

  describe "POST /v1/commerce/offerings/:id/checkout" do
    let(:offering) { Suma::Fixtures.offering.create(max_ordered_items_cumulative: 20, max_ordered_items_per_member: 5) }
    let!(:fulfillment) { Suma::Fixtures.offering_fulfillment_option(offering:).create }
    let(:product) { Suma::Fixtures.product.create }
    let!(:offering_product) { Suma::Fixtures.offering_product(product:, offering:).create }
    let!(:cart) { Suma::Fixtures.cart(offering:, member:).with_product(product, 2).create }

    it "starts a checkout and soft deletes any pending checkouts" do
      other_member_checkout = Suma::Fixtures.checkout(cart: Suma::Fixtures.cart(member:).create).create
      completed_checkout = Suma::Fixtures.checkout(cart:).completed.create

      post "/v1/commerce/offerings/#{offering.id}/checkout"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          offering: include(id: offering.id),
          items: contain_exactly(include(quantity: 2, product: include(product_id: product.id))),
          payment_instrument: nil,
          available_payment_instruments: [],
          fulfillment_option_id: fulfillment.id,
          available_fulfillment_options: contain_exactly(include(id: fulfillment.id)),
        )
      expect(other_member_checkout.refresh).to be_soft_deleted
      expect(completed_checkout.refresh).to_not be_soft_deleted
    end

    it "errors if there are no items in the cart" do
      cart.items.first.delete

      post "/v1/commerce/offerings/#{offering.id}/checkout"

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(code: "checkout_no_items"))
    end

    it "errors when lowering max per member inventory in an offering" do
      offering.update(max_ordered_items_per_member: 1)

      post "/v1/commerce/offerings/#{offering.id}/checkout"

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(code: "invalid_order_quantity"))
    end

    it "removes unavailable products from the checkout" do
      offering_product.delete

      post "/v1/commerce/offerings/#{offering.id}/checkout"

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(code: "checkout_no_items"))
    end

    it "errors if the member cannot access the offering due to constraints" do
      offering.add_eligibility_constraint(Suma::Fixtures.eligibility_constraint.create)

      post "/v1/commerce/offerings/#{offering.id}/checkout"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "eligibility_violation"))
    end

    it "errors if offering is closed" do
      offering.update(period_end: 1.day.ago)

      post "/v1/commerce/offerings/#{offering.id}/checkout"

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(code: "checkout_no_items"))
    end
  end

  describe "GET /v1/commerce/checkouts/:id" do
    let!(:cart) { Suma::Fixtures.cart(member:).with_any_product.create }
    let(:checkout) { Suma::Fixtures.checkout(cart:).populate_items.create }

    it "returns the checkout and other data" do
      get "/v1/commerce/checkouts/#{checkout.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: checkout.id)
    end

    it "errors if the checkout is not editable" do
      checkout.soft_delete

      get "/v1/commerce/checkouts/#{checkout.id}"

      expect(last_response).to have_status(403)
    end

    it "errors if the checkout does not belong to the member" do
      checkout.cart.update(member: Suma::Fixtures.member.create)

      get "/v1/commerce/checkouts/#{checkout.id}"

      expect(last_response).to have_status(403)
    end

    it "errors if the checkout has no items" do
      checkout.items_dataset.delete

      get "/v1/commerce/checkouts/#{checkout.id}"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/commerce/checkouts/:id/complete" do
    let(:offering) { Suma::Fixtures.offering.create }
    let!(:fulfillment) { Suma::Fixtures.offering_fulfillment_option(offering:).create }
    let(:product) { Suma::Fixtures.product.category(:food).create }
    let!(:offering_product) { Suma::Fixtures.offering_product(product:, offering:).create }
    let(:cart) { Suma::Fixtures.cart(offering:, member:).with_product(product, 2).create }
    let(:card) { Suma::Fixtures.card.member(member).create }
    let(:checkout) { Suma::Fixtures.checkout(cart:, card:).populate_items.create }
    let!(:member_ledger) { Suma::Fixtures.ledger.member(member).category(:food).create }
    let!(:platform_ledger) { Suma::Fixtures::Ledgers.ensure_platform_cash }

    around(:each) do |ex|
      Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.not_ready) do
        ex.run
      end
    end

    it "clears the cart, completes the checkout, creates an order, and returns the confirmation" do
      post "/v1/commerce/checkouts/#{checkout.id}/complete"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: checkout.id)
      expect(checkout.order).to be_a(Suma::Commerce::Order)
      expect(cart.refresh.items).to be_empty
      expect(checkout.refresh).to be_completed
    end

    it "errors if checkout is prohibited" do
      checkout.soft_delete

      post "/v1/commerce/checkouts/#{checkout.id}/complete"

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.that_includes(error: include(code: "checkout_fatal_error"))
    end

    it "sets the instrument on the checkout" do
      newcard = Suma::Fixtures.card.create(legal_entity: card.legal_entity)

      post "/v1/commerce/checkouts/#{checkout.id}/complete",
           payment_instrument: {payment_instrument_id: newcard.id, payment_method_type: "card"}

      expect(last_response).to have_status(200)
      expect(checkout.refresh).to have_attributes(payment_instrument: be === newcard)
    end

    it "errors if the member does not own the instrument" do
      newcard = Suma::Fixtures.card.create

      post "/v1/commerce/checkouts/#{checkout.id}/complete",
           payment_instrument: {payment_instrument_id: newcard.id, payment_method_type: "card"}

      expect(last_response).to have_status(403)
    end

    it "errors if the instrument is soft deleted" do
      newcard = Suma::Fixtures.card.create
      newcard.soft_delete

      post "/v1/commerce/checkouts/#{checkout.id}/complete",
           payment_instrument: {payment_instrument_id: newcard.id, payment_method_type: "card"}

      expect(last_response).to have_status(403)
    end

    it "does not require payment instrument if chargeable total is zero" do
      offering_product.update(customer_price_cents: 0, undiscounted_price: 0)
      checkout.update(payment_instrument: nil)

      post "/v1/commerce/checkouts/#{checkout.id}/complete"

      expect(last_response).to have_status(200)
    end

    it "errors if the checkout does not point to a payment instrument when required" do
      checkout.update(payment_instrument: nil)

      post "/v1/commerce/checkouts/#{checkout.id}/complete"

      expect(last_response).to have_status(409)
    end

    it "sets the fulfillment option" do
      newopt = Suma::Fixtures.offering_fulfillment_option(offering:).create

      post "/v1/commerce/checkouts/#{checkout.id}/complete", fulfillment_option_id: newopt.id

      expect(last_response).to have_status(200)
      expect(checkout.refresh).to have_attributes(fulfillment_option: be === newopt)
    end

    it "errors if the fulfillment option is not available" do
      newopt = Suma::Fixtures.offering_fulfillment_option.create

      post "/v1/commerce/checkouts/#{checkout.id}/complete", fulfillment_option_id: newopt.id

      expect(last_response).to have_status(403)
    end

    it "errors if max quantity is exceeded" do
      offering.update(max_ordered_items_cumulative: 1)

      post "/v1/commerce/checkouts/#{checkout.id}/complete"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "invalid_order_quantity"))
    end

    it "deletes the payment instrument if it is not being saved" do
      post "/v1/commerce/checkouts/#{checkout.id}/complete", save_payment_instrument: false

      expect(last_response).to have_status(200)
      expect(card.refresh).to be_soft_deleted
    end

    it "errors if the member cannot access the offering due to constraints" do
      offering.add_eligibility_constraint(Suma::Fixtures.eligibility_constraint.create)

      post "/v1/commerce/checkouts/#{checkout.id}/complete"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "eligibility_violation"))
    end
  end

  describe "GET /v1/commerce/checkouts/:id/confirmation" do
    let!(:cart) { Suma::Fixtures.cart(member:).with_any_product.create }
    let(:checkout) { Suma::Fixtures.checkout(cart:).populate_items.create }

    it "returns the completed checkout" do
      checkout.complete.save_changes

      get "/v1/commerce/checkouts/#{checkout.id}/confirmation"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: checkout.id)
    end

    it "errors if the checkout is not completed" do
      get "/v1/commerce/checkouts/#{checkout.id}/confirmation"

      expect(last_response).to have_status(403)
    end

    it "errors if the checkout does not belong to the member" do
      checkout.cart.update(member: Suma::Fixtures.member.create)

      get "/v1/commerce/checkouts/#{checkout.id}/confirmation"

      expect(last_response).to have_status(403)
    end

    it "errors if the checkout is more than 2 days old" do
      checkout.update(created_at: 3.days.ago)

      get "/v1/commerce/checkouts/#{checkout.id}/confirmation"

      expect(last_response).to have_status(403)
    end
  end

  describe "GET /v1/commerce/orders" do
    it "returns a full order history with the most recent 2 orders as detailed" do
      o2 = Suma::Fixtures.order.as_purchased_by(member).create(created_at: 10.days.ago)
      o3 = Suma::Fixtures.order.as_purchased_by(member).create(created_at: 9.days.ago)
      o4 = Suma::Fixtures.order.as_purchased_by(member).create(created_at: 8.days.ago)
      o1 = Suma::Fixtures.order.as_purchased_by(member).create(created_at: 11.days.ago)

      get "/v1/commerce/orders"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: have_same_ids_as(o4, o3, o2, o1).ordered,
        detailed_orders: have_same_ids_as(o4, o3),
      )
    end
  end

  describe "GET /v1/commerce/orders/unclaimed" do
    it "returns orders available to claim" do
      o1 = Suma::Fixtures.order.as_purchased_by(member).claimable.create
      o2 = Suma::Fixtures.order.as_purchased_by(member).claimed.create

      get "/v1/commerce/orders/unclaimed"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: have_same_ids_as(o1).ordered,
      )
    end
  end

  describe "GET /v1/commerce/orders/:id" do
    it "returns the order" do
      o = Suma::Fixtures.order.as_purchased_by(member).create

      get "/v1/commerce/orders/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the member does not own the order" do
      o = Suma::Fixtures.order.create

      get "/v1/commerce/orders/#{o.id}"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/commerce/orders/:id/modify_fulfillment" do
    let(:order) { Suma::Fixtures.order.as_purchased_by(member).create }

    it "can modify the fulfillment option" do
      opt = Suma::Fixtures.offering_fulfillment_option(offering: order.checkout.cart.offering).create

      post "/v1/commerce/orders/#{order.id}/modify_fulfillment", option_id: opt.id

      expect(last_response).to have_status(200)
      expect(order.checkout.refresh).to have_attributes(fulfillment_option: be === opt)
    end

    it "400s if the given ID is not an available fulfillment option" do
      opt = Suma::Fixtures.offering_fulfillment_option(offering: order.checkout.cart.offering).create
      opt.soft_delete

      post "/v1/commerce/orders/#{order.id}/modify_fulfillment", option_id: opt.id

      expect(last_response).to have_status(400)
    end
  end

  describe "POST /v1/commerce/orders/:id/claim" do
    let(:order_fac) { Suma::Fixtures.order.as_purchased_by(member) }
    it "claims a claimable order" do
      order = order_fac.claimable.create

      post "/v1/commerce/orders/#{order.id}/claim"

      expect(last_response).to have_status(200)
      expect(order.refresh).to have_attributes(fulfillment_status: "fulfilled")
    end

    it "409s if the order cannot be claimed" do
      order = order_fac.claimed.create

      post "/v1/commerce/orders/#{order.id}/claim"

      expect(last_response).to have_status(409)
    end
  end
end
