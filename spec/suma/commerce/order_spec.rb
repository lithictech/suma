# frozen_string_literal: true

RSpec.describe "Suma::Commerce::Order", :db do
  let(:described_class) { Suma::Commerce::Order }

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
end
