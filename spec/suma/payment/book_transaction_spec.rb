# frozen_string_literal: true

RSpec.describe "Suma::Payment::BookTransaction", :db do
  let(:described_class) { Suma::Payment::BookTransaction }

  it "sets the current actor appropriately" do
    expect(Suma::Fixtures.book_transaction.create.actor).to be_nil
    user = Suma::Fixtures.member.create
    admin = Suma::Fixtures.member.create
    Suma.set_request_user_and_admin(user, nil) do
      expect(Suma::Fixtures.book_transaction.create.actor).to be === user
    end
    Suma.set_request_user_and_admin(user, admin) do
      expect(Suma::Fixtures.book_transaction.create.actor).to be === admin
    end
  end

  describe "associations" do
    let(:b) { Suma::Fixtures.book_transaction.create }
    it "knows about the funding transaction that originated the receiver" do
      fx = Suma::Fixtures.funding_transaction.with_fake_strategy.create(originated_book_transaction: b)
      expect(b.refresh.originating_funding_transaction).to be === fx
    end

    it "knows the payout that originated the receiver" do
      px = Suma::Fixtures.payout_transaction.with_fake_strategy.create(
        originated_book_transaction: b,
      )
      expect(b.refresh.originating_payout_transaction).to be === px
    end

    it "knows about the payout that used the receiver for a credit" do
      px = Suma::Fixtures.payout_transaction.with_fake_strategy.create(
        originated_book_transaction: Suma::Fixtures.book_transaction.create,
        crediting_book_transaction: b,
        refunded_funding_transaction: Suma::Fixtures.funding_transaction.with_fake_strategy.create,
      )
      expect(b.refresh.credited_payout_transaction).to be === px
    end
  end

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
    it "uses 'mobility_trip' if the receiver has a mobility trip charge", lang: :en do
      ledger = Suma::Fixtures.ledger.member(member).category(:mobility).create
      trip = Suma::Fixtures.mobility_trip(member:).create
      trip.vendor_service.update(external_name: "Suma Bikes")
      charge = Suma::Fixtures.charge(mobility_trip: trip, member:, undiscounted_subtotal: money("$12.50")).create
      bx = Suma::Fixtures.book_transaction(amount: "$10.25").from(ledger).create
      charge.add_line_item(book_transaction: bx)
      expect(bx).to have_attributes(
        usage_details: contain_exactly(
          have_attributes(code: "mobility_trip", args: {discount_amount: cost("$2.25"), service_name: "Suma Bikes"}),
        ),
      )
    end

    it "uses 'commerce_order' if the receiver has a commerce charge" do
      ledger = Suma::Fixtures.ledger.member(member).category(:food).create
      order = Suma::Fixtures.order.create
      SequelTranslatedText.language("en") do
        order.checkout.cart.offering.description.update(string: "Suma Food")
        charge = Suma::Fixtures.charge(commerce_order: order, member:, undiscounted_subtotal: money("$12.50")).create
        bx = Suma::Fixtures.book_transaction(amount: "$10.25").from(ledger).create
        charge.add_line_item(book_transaction: bx)
        expect(bx).to have_attributes(
          usage_details: contain_exactly(
            have_attributes(code: "commerce_order", args: {discount_amount: cost("$2.25"), service_name: "Suma Food"}),
          ),
        )
      end
    end

    it "uses 'misc' if receiver has a charge without a mobility trip", lang: :en do
      ledger = Suma::Fixtures.ledger.member(member).create
      charge = Suma::Fixtures.charge(member:, undiscounted_subtotal: money("$12.50")).create
      bx = Suma::Fixtures.book_transaction(amount: "$12.50", memo: translated_text(en: "Hello")).from(ledger).create
      charge.add_line_item(book_transaction: bx)
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

    it "uses 'credit' if a receiver is crediting on a payout", :lang do
      fx = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      ba = Suma::Fixtures.bank_account.create(name: "My Savings", account_number: "991234")
      px = Suma::Fixtures::PayoutTransactions.refund_of(fx, ba, apply_credit: true)
      expect(px.crediting_book_transaction).to have_attributes(
        usage_details: contain_exactly(
          have_attributes(code: "credit", args: {memo: "Credit from suma"}),
        ),
      )
    end

    it "uses 'refund' if receiver is originated on a refund", :lang do
      fx = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      ba = Suma::Fixtures.bank_account.create(name: "My Savings", account_number: "991234")
      px = Suma::Fixtures::PayoutTransactions.refund_of(fx, ba, apply_credit: true)
      expect(px.originated_book_transaction).to have_attributes(
        usage_details: contain_exactly(
          have_attributes(code: "refund", args: {memo: "Refund sent to My Savings x-1234"}),
        ),
      )
    end

    it "uses 'misc' if receiver has no charge or funding transaction", lang: :es do
      bx = Suma::Fixtures.book_transaction(memo: translated_text(es: "Shoni")).create
      expect(bx).to have_attributes(
        usage_details: contain_exactly(
          have_attributes(code: "unknown", args: {memo: "Shoni"}),
        ),
      )
    end
  end

  describe "validations" do
    it "cannot have the same originating and receiving ledger id" do
      bt = Suma::Fixtures.book_transaction.create
      bt.receiving_ledger = bt.originating_ledger
      bt.validate
      expect(bt.errors).to eq({receiving_ledger_id: ["originating and receiving ledgers cannot be the same"]})
    end
  end
end
