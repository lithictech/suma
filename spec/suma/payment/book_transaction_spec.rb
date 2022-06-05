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
end
