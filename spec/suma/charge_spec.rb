# frozen_string_literal: true

RSpec.describe "Suma::Charge", :db do
  let(:described_class) { Suma::Charge }

  describe "associations" do
    it "is associated with book transactions" do
      ch = Suma::Fixtures.charge.create
      bx = Suma::Fixtures.book_transaction.create
      ch.add_contributing_book_transaction(bx)
      expect(ch.contributing_book_transactions).to have_same_ids_as(bx)
      expect(bx.charge_contributed_to).to be === ch
    end
  end

  it "knows how much was paid" do
    charge = Suma::Fixtures.charge.create
    Suma::Fixtures.charge_line_item.create(amount: money("$12.75"), charge:)
    expect(charge.discounted_subtotal).to cost("$12.75")
  end

  it "knows how much was synchronously funded" do
    charge = Suma::Fixtures.charge.create
    fx = Suma::Fixtures.funding_transaction.with_fake_strategy.create(amount: money("$12.50"))
    charge.add_associated_funding_transaction(fx)
    expect(charge.funded_amount).to cost("$12.50")
  end

  it "knows how much was paid in cash and non-cash" do
    charge = Suma::Fixtures.charge.create
    cash = Suma::Payment.ensure_cash_ledger(charge.member)
    bxcash = Suma::Fixtures.book_transaction.from(cash).create(amount: money("$12.50"))
    bxnoncash = Suma::Fixtures.book_transaction.from({account: cash.account}).create(amount: money("$5"))
    charge.add_contributing_book_transaction(bxcash)
    charge.add_contributing_book_transaction(bxnoncash)
    Suma::Fixtures.charge_line_item.create(amount: money("$17.75"), charge:)
    expect(charge.discounted_subtotal).to cost("$17.75") # Set by line items
    expect(charge.cash_paid_from_ledger).to cost("$12.50") # 12.50 bookx from cash
    expect(charge.noncash_paid_from_ledger).to cost("$5") # 5 from non-book. 3 self/offplatform is not noncash paid.
  end

  describe "validations" do
    it "requires a trip or order" do
      c = Suma::Charge.new(member: Suma::Fixtures.member.create, undiscounted_subtotal: "$1")
      expect { c.save_changes }.to raise_error(Sequel::CheckConstraintViolation)
    end
  end
end
