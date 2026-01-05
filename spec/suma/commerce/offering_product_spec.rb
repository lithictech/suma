# frozen_string_literal: true

RSpec.describe "Suma::Commerce::OfferingProduct", :db do
  let(:described_class) { Suma::Commerce::OfferingProduct }

  it "has an association to orders" do
    order = Suma::Fixtures.order.as_purchased_by(Suma::Fixtures.member.create).create
    op = order.checkout.items.first.offering_product
    expect(op.refresh.orders).to contain_exactly(be === order)
  end

  it "knows when it is discounted" do
    op = Suma::Fixtures.offering_product.create
    op.undiscounted_price = op.customer_price
    expect(op).to_not be_discounted
    op.undiscounted_price = op.customer_price + Money.new(1)
    expect(op).to be_discounted
    op.undiscounted_price = op.customer_price - Money.new(1)
    expect(op).to_not be_discounted
  end

  it "knows when it is available/closed" do
    op = Suma::Fixtures.offering_product.create
    expect(op).to be_available
    expect(op).to_not be_closed
    op.closed_at = Time.now
    expect(op).to_not be_available
    expect(op).to be_closed
  end

  it "errors if changing the customer price" do
    op = Suma::Fixtures.offering_product.costing("$1", "$2").create
    op.update(undiscounted_price: Money.new(500))
    expect { op.update(customer_price: Money.new(400)) }.to raise_error(Sequel::ValidationFailed, /customer_price/)
    op.refresh
    op.customer_price_currency = "EUR"
    expect { op.save_changes }.to raise_error(Sequel::ValidationFailed, /customer_price/)
  end

  describe "with_changes" do
    it "creates a clone of itself with a new price, closing the receiver" do
      orig = Suma::Fixtures.offering_product.costing("$1", "$2").create
      new_disc = orig.with_changes(undiscounted_price: Money.new(500))
      expect(orig).to be_closed
      expect(new_disc).to be_available
      expect(new_disc).to have_attributes(undiscounted_price: cost("$5"), customer_price: cost("$1"))
      new_cust = new_disc.with_changes(customer_price: Money.new(400))
      expect(new_disc).to be_closed
      expect(new_cust).to be_available
      expect(new_cust).to have_attributes(undiscounted_price: cost("$5"), customer_price: cost("$4"))
    end

    it "errors if no price is passed, or the passed price is the same value" do
      op = Suma::Fixtures.offering_product.create
      expect { op.with_changes }.to raise_error(Suma::InvalidPrecondition)
      expect { op.with_changes(undiscounted_price: op.undiscounted_price) }.to raise_error(Suma::InvalidPrecondition)
      expect { op.with_changes(customer_price: op.customer_price) }.to raise_error(Suma::InvalidPrecondition)
      expect do
        op.with_changes(customer_price: op.customer_price, undiscounted_price: Money.new(1))
      end.to_not raise_error
    end

    describe "when the receiver is closed" do
      it "errors if reopen_ok is false" do
        op = Suma::Fixtures.offering_product.closed.create
        expect { op.with_changes(undiscounted_price: Money.new(500)) }.to raise_error(Suma::InvalidPrecondition)
      end

      describe "and reopen_ok is true" do
        it "creates a new opened product and does not modify the original closed timestamp" do
          t = 5.hours.ago
          orig = Suma::Fixtures.offering_product.create(closed_at: t)
          newop = orig.with_changes(undiscounted_price: Money.new(500), reopen_ok: true)
          expect(orig).to be_closed
          expect(orig).to have_attributes(closed_at: match_time(t))
          expect(newop).to be_available
          expect(newop).to have_attributes(undiscounted_price: cost("$5"))
        end

        it "does not require a new price" do
          orig = Suma::Fixtures.offering_product.closed.create
          newop = orig.with_changes(reopen_ok: true)
          expect(newop).to have_attributes(undiscounted_price: orig.undiscounted_price)
        end
      end
    end
  end

  it "errors if more than one offering product is open for a given offering and product" do
    op1 = Suma::Fixtures.offering_product.create
    Suma::Fixtures.offering_product.create(offering: op1.offering)
    Suma::Fixtures.offering_product.create(product: op1.product)
    expect do
      Suma::Fixtures.offering_product.create(offering: op1.offering, product: op1.product)
    end.to raise_error(Sequel::UniqueConstraintViolation)
  end
end
