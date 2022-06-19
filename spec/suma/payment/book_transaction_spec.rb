# frozen_string_literal: true

RSpec.describe "Suma::Payment::BookTransaction", :db do
  let(:described_class) { Suma::Payment::BookTransaction }

  describe "directed" do
    it "can represent debits and credits" do
      bt = Suma::Fixtures.book_transaction.create(amount: money("$10"))
      expect(bt).to_not be_directed

      debit = bt.directed(bt.originating_ledger)
      expect(debit).to have_attributes(id: bt.id, amount: cost("-$10"), directed?: true)

      credit = bt.directed(bt.receiving_ledger)
      expect(credit).to have_attributes(id: bt.id, amount: cost("$10"), directed?: true)

      expect { debit.amount = money("$1") }.to raise_error(FrozenError)
      expect { debit.save_changes }.to raise_error(Sequel::Error, /save frozen object/)
    end
  end

  describe "usage_code" do
    let(:member) { Suma::Fixtures.member.create }
    it "uses 'mobility_trip' if the receiver has a mobility trip charge" do
      ledger = Suma::Fixtures.ledger.member(member).category(:mobility).create
      trip = Suma::Fixtures.mobility_trip(member:).create
      trip.vendor_service.update(external_name: "Suma Bikes")
      charge = Suma::Fixtures.charge(mobility_trip: trip, member:, undiscounted_subtotal: money("$12.50")).create
      bx = Suma::Fixtures.book_transaction(amount: "$10.25").from(ledger).create
      bx.add_charge(charge)
      expect(bx).to have_attributes(
        usage_details: contain_exactly(
          have_attributes(code: "mobility_trip", args: {discount_amount: cost("$2.25"), service_name: "Suma Bikes"}),
        ),
      )
    end

    it "uses 'misc' if receiver has a charge without a mobility trip" do
      ledger = Suma::Fixtures.ledger.member(member).create
      charge = Suma::Fixtures.charge(member:, undiscounted_subtotal: money("$12.50")).create
      bx = Suma::Fixtures.book_transaction(amount: "$12.50", memo: "Hello").from(ledger).create
      bx.add_charge(charge)
      expect(bx).to have_attributes(
        usage_details: contain_exactly(
          have_attributes(code: "misc", args: {discount_amount: cost("$0"), service_name: "Hello"}),
        ),
      )
    end

    it "uses 'funding' if receiver has a funding transaction" do
      ba = Suma::Fixtures.bank_account.create(name: "My Savings", account_number: "991234")
      fx = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      fx.strategy.set_response(:originating_instrument, ba)
      expect(fx.originated_book_transaction).to have_attributes(
        usage_details: contain_exactly(
          have_attributes(code: "funding", args: {account_label: "My Savings x-1234"}),
        ),
      )
    end

    it "uses 'misc' if receiver has no charge or funding transaction" do
      bx = Suma::Fixtures.book_transaction(memo: "Shoni").create
      expect(bx).to have_attributes(
        usage_details: contain_exactly(
          have_attributes(code: "unknown", args: {memo: "Shoni"}),
        ),
      )
    end
  end
end
