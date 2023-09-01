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
  end

  describe "datasets" do
    it "can find offerings available at a given time" do
      o = Suma::Fixtures.offering(period: 3.days.ago..3.days.from_now).create
      expect(described_class.available_at(Time.now).all).to have_same_ids_as(o)
      expect(described_class.available_at(5.days.ago).all).to be_empty
      expect(described_class.available_at(5.days.from_now).all).to be_empty
    end

    it "can find offerings eligible to a member based on constraints" do
      mem_no_constraints = Suma::Fixtures.member.create
      mem_verified_constraint = Suma::Fixtures.member.create
      mem_pending_constraint = Suma::Fixtures.member.create
      mem_rejected_constraint = Suma::Fixtures.member.create

      constraint = Suma::Fixtures.eligibility_constraint.create
      mem_verified_constraint.add_verified_eligibility_constraint(constraint)
      mem_pending_constraint.add_pending_eligibility_constraint(constraint)
      mem_rejected_constraint.add_rejected_eligibility_constraint(constraint)

      no_constraint = Suma::Fixtures.offering.create
      with_constraint = Suma::Fixtures.offering.with_constraints(constraint).create

      expect(described_class.eligible_to(mem_no_constraints).all).to have_same_ids_as(no_constraint)
      expect(described_class.eligible_to(mem_verified_constraint).all).to have_same_ids_as(
        no_constraint,
        with_constraint,
      )
      expect(described_class.eligible_to(mem_pending_constraint).all).to have_same_ids_as(no_constraint)
      expect(described_class.eligible_to(mem_rejected_constraint).all).to have_same_ids_as(no_constraint)

      # Test the instance methods
      expect(no_constraint).to be_eligible_to(mem_no_constraints)
      expect(no_constraint).to be_eligible_to(mem_verified_constraint)
      expect(no_constraint).to be_eligible_to(mem_pending_constraint)

      expect(with_constraint).to_not be_eligible_to(mem_no_constraints)
      expect(with_constraint).to be_eligible_to(mem_verified_constraint)
      expect(with_constraint).to_not be_eligible_to(mem_pending_constraint)
    end
  end

  describe "images" do
    it "orders images by ordinal" do
      p = Suma::Fixtures.offering.create
      i1 = p.add_image({uploaded_file: Suma::Fixtures.uploaded_file.create, ordinal: 1})
      i3 = p.add_image({uploaded_file: Suma::Fixtures.uploaded_file.create, ordinal: 3})
      i2 = p.add_image({uploaded_file: Suma::Fixtures.uploaded_file.create, ordinal: 2})
      expect(p.refresh.images).to have_same_ids_as(i1, i2, i3)
    end
  end

  describe "images?" do
    it "returns the 'unavailable' image if there are none" do
      p = Suma::Fixtures.offering.create
      expect(p.images).to be_empty
      expect(p.images?).to contain_exactly(
        have_attributes(ordinal: 0.0, uploaded_file: have_attributes(opaque_id: "missing")),
      )
    end
  end

  describe "#begin_order_fulfillment" do
    now = Time.now
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

  describe "#prohibit_charge_for(checkout)" do
    it "returns true if checkout cart offering prohibits charges" do
      member = Suma::Fixtures.member.create
      Suma::Payment.ensure_cash_ledger(member)
      offering = Suma::Fixtures.offering(prohibit_charge_at_checkout: true).create
      cart = Suma::Fixtures.cart(member:, offering:).with_any_product.create
      checkout = Suma::Fixtures.checkout(cart:).populate_items.create

      is_offering_prohibited = checkout.cart.offering.prohibit_charge_for(checkout)
      expect(is_offering_prohibited).to eq(true)
    end
  end
end
