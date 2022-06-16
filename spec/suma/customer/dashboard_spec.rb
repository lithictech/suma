# frozen_string_literal: true

require "suma/member/dashboard"

RSpec.describe Suma::Member::Dashboard, :db do
  let(:member) { Suma::Fixtures.member.create }

  it "can represent a blank/empty member" do
    d = described_class.new(member)
    expect(d).to have_attributes(
      payment_account_balance: cost("$0"),
      lifetime_savings: cost("$0"),
      ledger_lines: be_empty,
    )
  end

  it "can represent a member with ledgers and transactions" do
    cash_ledger = Suma::Fixtures.ledger.member(member).category(:cash).create
    grocery_ledger = Suma::Fixtures.ledger.member(member).category(:food).create
    # Add charges, one with transactions
    charge1 = Suma::Fixtures.charge(member:).create(undiscounted_subtotal: money("$30"))
    charge1.add_book_transaction(Suma::Fixtures.book_transaction.from(cash_ledger).create(amount: money("$20"),
                                                                                          apply_at: 20.days.ago,))
    charge1.add_book_transaction(Suma::Fixtures.book_transaction.from(grocery_ledger).create(amount: money("$5"),
                                                                                             apply_at: 21.days.ago,))
    charge2 = Suma::Fixtures.charge(member:).create(undiscounted_subtotal: money("$4.31"))
    # Add book transactions for funding events
    Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$27"))
    d = described_class.new(member)
    expect(d).to have_attributes(
      payment_account_balance: cost("$2"),
      lifetime_savings: cost("$9.31"),
      ledger_lines: match(
        [
          have_attributes(amount: cost("$27")),
          have_attributes(amount: cost("-$20")),
          have_attributes(amount: cost("-$5")),
        ],
      ),
    )
  end
end
