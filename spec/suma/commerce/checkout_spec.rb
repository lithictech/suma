# frozen_string_literal: true

RSpec.describe "Suma::Commerce::Checkout", :db do
  let(:described_class) { Suma::Commerce::Checkout }

  describe "cost accessors" do
    let(:member) { Suma::Fixtures.member.create }
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.category(:cash).create }
    let!(:offering_product) { Suma::Fixtures.offering_product(product:, offering:).costing("$20", "$30").create }
    let(:cart) { Suma::Fixtures.cart(offering:, member:).with_product(product, 2).create }
    let(:checkout) { Suma::Fixtures.checkout(cart:).populate_items.create }
    let!(:cash_ledger) { Suma::Fixtures.ledger.member(member).category(:cash).create }
    let!(:platform_ledger) { Suma::Fixtures::Ledgers.ensure_platform_cash }

    it "are calculated correctly" do
      Suma::Fixtures.book_transaction(amount: money("$10")).to(cash_ledger).create

      expect(checkout).to have_attributes(
        undiscounted_cost: cost("$60"),
        customer_cost: cost("$40"),
        savings: cost("$20"),
        handling: cost("$0"),
        taxable_cost: cost("$40"),
        tax: cost("$0"),
        total: cost("$40"),
      )
      contribs = checkout.actual_charge_contributions(apply_at: Time.now)
      expect(contribs.cash.amount).to cost("$10")
      expect(contribs.remainder).to cost("$30")
    end
  end

  describe "requires_payment_instrument?" do
    let(:member) { Suma::Fixtures.member.registered_as_stripe_customer.create }
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.category(:cash).create }
    let!(:offering_product) { Suma::Fixtures.offering_product(offering:, product:).costing("$3", "$0").create }
    let(:cart) { Suma::Fixtures.cart(offering:, member:).with_product(product, 2).create }
    let(:checkout) { Suma::Fixtures.checkout(cart:).populate_items.create }

    it "returns true depending if the chargeable total is zero" do
      Suma::Payment.ensure_cash_ledger(member)
      expect(checkout.cost_info(at: Time.now)).to be_requires_payment_instrument

      offering_product.update_without_validate(customer_price_cents: 0)

      checkout.refresh
      expect(checkout.cost_info(at: Time.now).chargeable_total).to cost(0)
      expect(checkout.cost_info(at: Time.now)).to_not be_requires_payment_instrument
    end
  end

  describe "checkout_prohibited_reason" do
    let(:member) { Suma::Fixtures.member.create }
    let(:offering) { Suma::Fixtures.offering.create }
    let(:cart) { Suma::Fixtures.cart(member:, offering:).with_any_product.create }
    let(:checkout) { Suma::Fixtures.checkout(cart:).populate_items.with_payment_instrument.create }

    before(:each) do
      Suma::Payment.ensure_cash_ledger(member)
    end

    def prohibited_reason
      return checkout.cost_info(at: Time.now).checkout_prohibited_reason
    end

    it "is nil if nothing is wrong" do
      expect(prohibited_reason).to eq(nil)
    end

    it "is :not_editable if the checkout is not editable" do
      checkout.soft_delete
      expect(prohibited_reason).to eq(:not_editable)
    end

    it "is :requires_payment_instrument if an instrument is required and not set" do
      checkout.payment_instrument = nil
      expect(prohibited_reason).to eq(:requires_payment_instrument)
      cart.items.first.offering_product.update_without_validate(customer_price: Money.new(0))
      checkout.refresh
      expect(prohibited_reason).to eq(nil)
    end

    it "is :offering_products_unavailable if all offering products are unavailable" do
      offering.update(period_end: 1.day.ago)
      expect(prohibited_reason).to eq(:offering_products_unavailable)
    end
  end

  describe "create_order" do
    let(:member) { Suma::Fixtures.member.registered_as_stripe_customer.create }
    let(:offering) { Suma::Fixtures.offering.create }
    let!(:fulfillment) { Suma::Fixtures.offering_fulfillment_option(offering:).create }
    let(:product) { Suma::Fixtures.product.category(:cash).create }
    let!(:offering_product) { Suma::Fixtures.offering_product(product:, offering:).costing("$20", "$30").create }
    let(:cart) { Suma::Fixtures.cart(offering:, member:).with_product(product, 2).create }
    let(:card) { Suma::Fixtures.card.member(member).create }
    let(:checkout) { Suma::Fixtures.checkout(cart:, card:).populate_items.create }
    let!(:cash_ledger) { Suma::Fixtures.ledger.member(member).category(:cash).create }
    let!(:platform_ledger) { Suma::Fixtures::Ledgers.ensure_platform_cash }

    around(:each) do |ex|
      Suma::Payment::FundingTransaction.force_fake(proc { Suma::Payment::FakeStrategy.create.not_ready }) do
        ex.run
      end
    end

    def create_order(amount=nil, checkout_: checkout)
      amount ||= checkout_.items.sum(&:customer_cost)
      checkout_.create_order(apply_at: Time.now, cash_charge_amount: amount)
    end

    it "errors if charging is prohibited" do
      checkout.soft_delete
      expect { create_order }.to raise_error(described_class::Prohibited, /not_editable/)
    end

    it "creates the order from the checkout" do
      order = create_order
      expect(order).to have_attributes(
        checkout: be === checkout,
        order_status: "open",
        fulfillment_status: "unfulfilled",
      )
      expect(checkout).to be_completed
      expect(checkout.card).to be_soft_deleted
    end

    it "deletes the cart items, and copies their quantity to the checkout items" do
      create_order
      expect(checkout.cart.items).to be_empty
      expect(checkout.items.first).to have_attributes(quantity: 2, cart_item: nil)
    end

    it "does not delete the payment instrument if it is being saved" do
      checkout.update(save_payment_instrument: true)
      create_order
      expect(checkout.card).to_not be_soft_deleted
    end

    it "prevents soft deleting payment instrument if it is not required" do
      checkout.update(payment_instrument: nil)
      offering_product.update_without_validate(customer_price_cents: 0)
      # Ensure payment is not required
      expect(checkout.cost_info(at: Time.now)).to_not be_requires_payment_instrument
      create_order(amount = money("$0"))
      expect(checkout.card).to be_nil
      expect(card.refresh).to_not be_soft_deleted
    end

    it "creates a charge for the customer cost" do
      order = create_order
      expect(order).to be_a(Suma::Commerce::Order)
      expect(order.charges).to have_length(1)
      expect(order.charges.first).to have_attributes(
        undiscounted_subtotal: cost("$60"), discounted_subtotal: cost("$40"),
      )
    end

    it "creates a funding transaction for the chargeable amount" do
      Suma::Fixtures.book_transaction(amount: money("$5")).to(cash_ledger).create
      order = create_order(money("$35")) # take into account the $5 existing balance
      expect(member.payment_account.originated_funding_transactions).to contain_exactly(
        have_attributes(amount: cost("$35"), status: "created"),
      )
      expect(order.charges.first.associated_funding_transactions).to contain_exactly(
        be === member.payment_account.originated_funding_transactions.first,
      )
    end

    it "errors if the amount to be charged, and what is calculated as needing to be charged, differ" do
      Suma::Fixtures.book_transaction(amount: money("$5")).to(cash_ledger).create
      expect { create_order }.to raise_error(described_class::Prohibited, /calculated charge of/)
    end

    it "creates the order in fulfilling if the offering has begun fulfillment" do
      offering.update(begin_fulfillment_at: 1.minute.ago)
      order = create_order
      expect(order).to have_attributes(
        order_status: "open",
        fulfillment_status: "fulfilling",
      )
    end

    describe "with a complex, multi-product, multi-ledger product and payment setup" do
      it "generates the right funding and book transaction, as per the documentation" do
        cash_vsc = Suma::Vendor::ServiceCategory.cash
        food_vsc = Suma::Fixtures.vendor_service_category(name: "Food", parent: cash_vsc).create
        holidaymeal_vsc = Suma::Fixtures.vendor_service_category(name: "Holiday Special", parent: food_vsc).create
        member = Suma::Fixtures.member.create

        cash_ledger = Suma::Payment.ensure_cash_ledger(member)
        ledger_fac = Suma::Fixtures.ledger.member(member)
        food_ledger = ledger_fac.with_categories(food_vsc).create(name: "food")
        holidaymeal_ledger = ledger_fac.with_categories(holidaymeal_vsc).create(name: "holidays")

        # Make sure we debit existing ledgers properly
        book_cash = Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$13"))
        book_food = Suma::Fixtures.book_transaction.to(food_ledger).create(amount: money("$3"))
        book_holiday = Suma::Fixtures.book_transaction.to(holidaymeal_ledger).create(amount: money("$0.30"))

        offering = Suma::Fixtures.offering.create
        food_product1 = Suma::Fixtures.product.with_categories(food_vsc).create
        food_op1 = Suma::Fixtures.offering_product(product: food_product1, offering:).costing("$400", "$500").create

        food_product2 = Suma::Fixtures.product.with_categories(food_vsc).create
        food_op2 = Suma::Fixtures.offering_product(product: food_product2, offering:).costing("$400", "$500").create

        holiday_product = Suma::Fixtures.product.with_categories(holidaymeal_vsc).create
        holiday_op = Suma::Fixtures.offering_product(product: holiday_product, offering:).costing("$40", "$50").create

        cash_product = Suma::Fixtures.product.with_categories(Suma::Vendor::ServiceCategory[slug: "cash"]).create
        cash_op = Suma::Fixtures.offering_product(product: cash_product, offering:).costing("$4", "$5").create

        cart = Suma::Fixtures.cart(offering:, member:).
          with_product(food_product1, 2).
          with_product(food_product2, 1).
          with_product(holiday_product, 1).
          with_product(cash_product, 1).
          create
        checkout = Suma::Fixtures.checkout(cart:, card: Suma::Fixtures.card.member(member).create).
          populate_items.
          create

        customer_cost = money("$1244")
        chargeable_total = customer_cost - book_cash.amount - book_food.amount - book_holiday.amount
        order = create_order(chargeable_total, checkout_: checkout)
        expect(order.charges).to have_length(1)
        expect(order.charges.first).to have_attributes(
          discounted_subtotal: customer_cost,
          undiscounted_subtotal: cost("$1555"),
        )
        expect(order.charges.first.book_transactions).to contain_exactly(
          have_attributes(amount: cost("$3"), originating_ledger: be === food_ledger),
          have_attributes(amount: cost("$0.30"), originating_ledger: be === holidaymeal_ledger),
          have_attributes(amount: cost("$1240.70"), originating_ledger: be === cash_ledger),
        )
        expect(member.payment_account.originated_funding_transactions).to contain_exactly(
          have_attributes(amount: cost("$1227.70")),
        )
        expect(member.payment_account.all_book_transactions(reload: true)).to contain_exactly(
          # These are the initial credits
          have_attributes(amount: cost("$13"), receiving_ledger: be === cash_ledger),
          have_attributes(amount: cost("$3"), receiving_ledger: be === food_ledger),
          have_attributes(amount: cost("$0.30"), receiving_ledger: be === holidaymeal_ledger),
          # These are the debits, zeroing out the ledgers
          have_attributes(amount: cost("$3"), originating_ledger: be === food_ledger),
          have_attributes(amount: cost("$0.30"), originating_ledger: be === holidaymeal_ledger),
          # This is the total cash charge, both the original $13 cash credit AND the $1227.70 funding
          have_attributes(amount: cost("$1240.70"), originating_ledger: be === cash_ledger),
          # Here is the credit from the platform back to the member, for their charged chart
          have_attributes(amount: cost("$1227.70"), receiving_ledger: be === cash_ledger),
        )
      end

      it "does not debit unused, but potentially useful, ledgers" do
        top_vsc = Suma::Fixtures.vendor_service_category(name: "Everything").create
        mid_vsc = Suma::Fixtures.vendor_service_category(name: "Food", parent: top_vsc).create
        low_vsc = Suma::Fixtures.vendor_service_category(name: "Organic", parent: mid_vsc).create
        member = Suma::Fixtures.member.create

        cash_ledger = Suma::Payment.ensure_cash_ledger(member)
        top_ledger = Suma::Fixtures.ledger.member(member).with_categories(top_vsc).create
        mid_ledger = Suma::Fixtures.ledger.member(member).with_categories(mid_vsc).create
        low_ledger = Suma::Fixtures.ledger.member(member).with_categories(low_vsc).create

        offering = Suma::Fixtures.offering.create

        low_product = Suma::Fixtures.product.with_categories(low_vsc).create
        low_op = Suma::Fixtures.offering_product(product: low_product, offering:).costing("$40", "$50").create

        cart = Suma::Fixtures.cart(offering:, member:).
          with_product(low_product, 1).
          create
        checkout = Suma::Fixtures.checkout(cart:, card: Suma::Fixtures.card.member(member).create).
          populate_items.
          create

        order = create_order(checkout_: checkout)
        expect(order.charges).to have_length(1)
        expect(order.charges.first).to have_attributes(
          discounted_subtotal: cost("40"),
          undiscounted_subtotal: cost("$50"),
        )
        expect(order.charges.first.book_transactions).to contain_exactly(
          have_attributes(originating_ledger: be === cash_ledger, amount: cost("$40")),
        )
        expect(member.payment_account.all_book_transactions(reload: true)).to contain_exactly(
          have_attributes(originating_ledger: be === cash_ledger, amount: cost("$40")),
          have_attributes(receiving_ledger: be === cash_ledger, amount: cost("$40")),
        )
      end
    end

    describe "inventory behavior" do
      it "errors if the order quantity exceeds the maximum allowed on the offering" do
        offering.update(max_ordered_items_cumulative: 1)
        expect { create_order }.to raise_error(described_class::MaxQuantityExceeded)
      end

      it "errors if the order quantity of a limited item exceeds what is available" do
        product.inventory!.update(limited_quantity: true, quantity_on_hand: 3, quantity_pending_fulfillment: 2)

        cart.delete_all_items
        cart.add_item(product:, quantity: 1, timestamp: 0)
        co1 = Suma::Fixtures.checkout(cart:, card:).populate_items.create
        expect { create_order(checkout_: co1) }.to_not raise_error

        cart.add_item(product:, quantity: 1, timestamp: 0)
        co2 = Suma::Fixtures.checkout(cart:, card:).populate_items.create
        expect { create_order(checkout_: co2) }.to raise_error(described_class::MaxQuantityExceeded)
      end

      it "increments pending fulfillment counts of products" do
        product.inventory!.update(quantity_on_hand: 5, quantity_pending_fulfillment: 1)
        cart.delete_all_items
        cart.add_item(product:, quantity: 2, timestamp: 0)
        create_order(checkout_: Suma::Fixtures.checkout(cart:, card:).populate_items.create)
        expect(product.refresh.inventory).to have_attributes(quantity_on_hand: 5, quantity_pending_fulfillment: 3)
      end
    end
  end

  describe "available_fulfillment_options" do
    it "excludes deleted options" do
      checkout = Suma::Fixtures.checkout.create
      opt_fac = Suma::Fixtures.offering_fulfillment_option(offering: checkout.cart.offering)
      checkout.fulfillment_option.soft_delete
      opt1 = opt_fac.create
      opt2 = opt_fac.create
      opt2.soft_delete
      expect(checkout.available_fulfillment_options).to have_same_ids_as(opt1)
    end
  end

  describe "soft delete" do
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.in_offering(offering).create }
    let(:cart) { Suma::Fixtures.cart(offering:).with_product(product).create }
    let(:checkout) { Suma::Fixtures.checkout(cart:).populate_items.create }
    it "copies quantity and replaces cart items" do
      expect(checkout.items).to contain_exactly(
        have_attributes(cart_item: be === cart.items.first, immutable_quantity: nil),
      )
      checkout.soft_delete
      expect(checkout.items).to contain_exactly(
        have_attributes(cart_item: nil, immutable_quantity: 1),
      )
      cart.items_dataset.delete
    end
  end
end
