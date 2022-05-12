# frozen_string_literal: true

require "suma/customer/dashboard"

RSpec.describe Suma::Customer::Dashboard, :db do
  let(:described_class) { Suma::Customer::Dashboard }
  let(:customer) { Suma::Fixtures.customer.create }

  it "can represent a blank/empty customer" do
    d = described_class.new(customer)
    expect(d).to have_attributes(
      payment_account_balance: cost("$0"),
      lifetime_savings: cost("$0"),
      ledger_lines: be_empty,
    )
  end

  it "can represent a customer with ledgers and transactions" do
    cash_ledger = Suma::Fixtures.ledger.customer(customer).category(:cash).create
    grocery_ledger = Suma::Fixtures.ledger.customer(customer).category(:food).create
    # Add charges, one with transactions
    charge1 = Suma::Fixtures.charge(customer:).create(undiscounted_subtotal: money("$30"))
    charge1.add_book_transaction(Suma::Fixtures.book_transaction.from(cash_ledger).create(amount: money("$20")))
    charge1.add_book_transaction(Suma::Fixtures.book_transaction.from(grocery_ledger).create(amount: money("$5")))
    charge2 = Suma::Fixtures.charge(customer:).create(undiscounted_subtotal: money("$4.31"))
    # Add book transactions for funding events
    Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$27"))
    d = described_class.new(customer)
    expect(d).to have_attributes(
      payment_account_balance: cost("$2"),
      lifetime_savings: cost("$9.31"),
      ledger_lines: contain_exactly(
        have_attributes(amount: cost("$27")),
        have_attributes(amount: cost("-$5")),
        have_attributes(amount: cost("-$20")),
      ),
    )
    expect(d.ledger_lines[0]).to have_attributes(amount: cost("$27"))
    expect(d.ledger_lines[1]).to have_attributes(amount: cost("-$5"))
    expect(d.ledger_lines[2]).to have_attributes(amount: cost("-$20"))
  end
end
