# frozen_string_literal: true

RSpec.describe "Suma::Commerce::Offering", :db do
  let(:described_class) { Suma::Commerce::Offering }

  describe "associations" do
    it "knows related carts" do
      cart = Suma::Fixtures.cart.create
      expect(cart.offering.carts).to contain_exactly(be === cart)
      expect(described_class.where(carts: [cart]).all).to contain_exactly(be === cart.offering)
    end

    it "knows related orders, products, and their counts" do
      order = Suma::Fixtures.order.as_purchased_by(Suma::Fixtures.member.create).create
      offering = order.checkout.cart.offering.refresh
      product = order.checkout.items.first.offering_product.product
      Suma::Fixtures.offering_product(offering:, product:).closed.create # Make sure we only get one product
      Suma::Fixtures.order.create
      o2 = Suma::Fixtures.order.create
      o2.checkout.cart.update(offering:)

      expect(offering.products).to have_same_ids_as(product)
      expect(offering.product_count).to eq(1)
      expect(Suma::Commerce::Offering.where(id: offering.id).all.first.product_count).to eq(1)

      expect(offering.orders).to have_same_ids_as(order, o2)
      expect(offering.order_count).to eq(2)
      expect(Suma::Commerce::Offering.where(id: offering.id).all.first.order_count).to eq(2)
    end

    it "knows the quantity on all uncanceled orders" do
      offering = Suma::Fixtures.offering.create
      product = Suma::Fixtures.product.create
      Suma::Fixtures.offering_product(offering:, product:).create
      cart_fac = Suma::Fixtures.cart(offering:)
      checkout1 = Suma::Fixtures.checkout(cart: cart_fac.with_product(product, 10).create).
        with_payment_instrument.
        populate_items.
        completed.
        create
      order1 = Suma::Fixtures.order.create(checkout: checkout1)
      checkout2 = Suma::Fixtures.checkout(cart: cart_fac.with_product(product, 20).create).
        with_payment_instrument.
        populate_items.
        completed.
        create
      order2 = Suma::Fixtures.order.create(checkout: checkout2, order_status: "canceled")

      expect(offering.orders.map { |o| o.checkout.items }.flatten.sum(&:quantity)).to eq(30)
      expect(offering.total_ordered_items).to eq(10)
      expect(refetch_for_eager(offering).total_ordered_items).to eq(10)
      expect(offering.total_ordered_items_by_member).to eq({checkout1.cart.member_id => 10})
      expect(refetch_for_eager(offering).total_ordered_items_by_member).to eq({checkout1.cart.member_id => 10})

      empty_offering = Suma::Fixtures.offering.create
      expect(empty_offering.total_ordered_items).to eq(0)
      expect(refetch_for_eager(empty_offering).total_ordered_items).to eq(0)
      expect(refetch_for_eager(empty_offering).total_ordered_items_by_member).to eq({})
    end

    it "knows its program enrollments" do
      e1 = Suma::Fixtures.program_enrollment.create
      e2 = Suma::Fixtures.program_enrollment.create
      e3 = Suma::Fixtures.program_enrollment.create

      o = Suma::Fixtures.offering.create
      o.add_program(e1.program)
      o.add_program(e2.program)
      expect(o.program_enrollments).to have_same_ids_as(e1, e2)
    end
  end

  describe "datasets" do
    it "can find offerings available at a given time" do
      o = Suma::Fixtures.offering(period: 3.days.ago..3.days.from_now).create
      expect(described_class.available_at(Time.now).all).to have_same_ids_as(o)
      expect(described_class.available_at(5.days.ago).all).to be_empty
      expect(described_class.available_at(5.days.from_now).all).to be_empty
    end
  end

  describe "#begin_order_fulfillment" do
    let(:now) { Time.now }
    it "begins fulfillment on qualifying orders" do
      o1 = Suma::Fixtures.order.as_purchased_by(Suma::Fixtures.member.create).create
      offering = o1.checkout.cart.offering
      offering.update(begin_fulfillment_at: 1.minute.ago)
      o2 = Suma::Fixtures.order.create(order_status: "canceled")
      o2.checkout.cart.update(offering:)

      expect(offering.begin_order_fulfillment(now:)).to eq(1)
      expect(o1.refresh).to have_attributes(fulfillment_status: "fulfilling")
      expect(o2.refresh).to have_attributes(fulfillment_status: "unfulfilled")
    end

    it "returns -1 if the time for fulfillment has not passed" do
      offering = Suma::Fixtures.offering.create(begin_fulfillment_at: 1.hour.from_now)
      expect(offering.begin_order_fulfillment(now:)).to eq(-1)
    end

    it "returns -1 if the offering does not use timed fulfillment" do
      offering = Suma::Fixtures.offering.create(begin_fulfillment_at: nil)
      expect(offering.begin_order_fulfillment(now:)).to eq(-1)
    end
  end

  describe "#period_end_visible" do
    it "returns nil if the offering ends far in the future" do
      t = 1.year.from_now
      o = Suma::Fixtures.offering.create(period: 1.year.ago..t)
      expect(o.period_end_visible).to match_time(t)
      o.period_end = 10.years.from_now
      expect(o.period_end_visible).to be_nil
    end
  end
end
