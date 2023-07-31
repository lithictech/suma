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
    d.minimum_recent_lines = 3
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

  describe "recent_lines" do
    let(:account) { Suma::Fixtures.payment_account.create }
    let!(:cash_ledger) { Suma::Fixtures.ledger(account:).category(:cash).create(name: "Dolla") }
    let!(:grocery_ledger) { Suma::Fixtures.ledger(account:).category(:food).create(name: "Grub") }

    it "includes the last 60 days of transactions" do
      d = described_class.new(account.ledgers)
      d.minimum_recent_lines = 2

      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$1"))
      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$2"), apply_at: 2.hours.ago)
      Suma::Fixtures.book_transaction.to(grocery_ledger).create(amount: money("$3"), apply_at: 3.hours.ago)
      Suma::Fixtures.book_transaction.to(grocery_ledger).create(amount: money("$4"), apply_at: 4.hours.ago)
      expect(d).to have_attributes(
        recent_lines: match(
          [
            have_attributes(amount: cost("$1")),
            have_attributes(amount: cost("$2")),
            have_attributes(amount: cost("$3")),
            have_attributes(amount: cost("$4")),
          ],
        ),
      )
    end

    it "always includes a minimum number of transactions if not enough are recent" do
      d = described_class.new(account.ledgers)
      d.minimum_recent_lines = 3

      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$1"))
      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$2"), apply_at: 100.days.ago)
      Suma::Fixtures.book_transaction.to(grocery_ledger).create(amount: money("$3"), apply_at: 101.days.ago)
      Suma::Fixtures.book_transaction.to(grocery_ledger).create(amount: money("$4"), apply_at: 102.days.ago)
      expect(d).to have_attributes(
        recent_lines: match(
          [
            have_attributes(amount: cost("$1")),
            have_attributes(amount: cost("$2")),
            have_attributes(amount: cost("$3")),
          ],
        ),
      )
    end
  end
end
