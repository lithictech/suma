# frozen_string_literal: true

require "suma/payment/ledgers_view"

RSpec.describe Suma::Payment::LedgersView, :db do
  it "can represent empty ledgers" do
    d = described_class.new([])
    expect(d).to have_attributes(
      total_balance: cost("$0"),
      recent_lines: [],
      ledgers: [],
    )
  end

  it "can represent ledgers and transactions" do
    account = Suma::Fixtures.payment_account.create
    cash_ledger = Suma::Fixtures.ledger(account:).category(:cash).create(name: "Dolla")
    grocery_ledger = Suma::Fixtures.ledger(account:).category(:food).create(name: "Grub")
    Suma::Fixtures.book_transaction.from(cash_ledger).create(amount: money("$20"), apply_at: 20.days.ago)
    Suma::Fixtures.book_transaction.from(grocery_ledger).create(amount: money("$5"), apply_at: 21.days.ago)
    Suma::Fixtures.book_transaction.from(grocery_ledger).create(amount: money("$1"), apply_at: 80.days.ago)
    Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$27"))
    d = described_class.new(account.ledgers)
    expect(d).to have_attributes(
      total_balance: cost("$1"),
      recent_lines: match(
        [
          have_attributes(amount: cost("$27")),
          have_attributes(amount: cost("-$20")),
          have_attributes(amount: cost("-$5")),
        ],
      ),
      ledgers: have_same_ids_as(cash_ledger, grocery_ledger).ordered,
    )
  end
end
