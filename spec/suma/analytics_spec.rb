# frozen_string_literal: true

RSpec.describe Suma::Analytics, :db do
  describe "upsert_from_transactional_model" do
    it "can upsert a handled models" do
      m = Suma::Fixtures.member.create
      described_class.upsert_from_transactional_model(m)
      expect(Suma::Analytics::Member.all).to have_length(1)
    end

    it "noops if there is no denormalizer" do
      m = Suma::Fixtures.uploaded_file.create
      described_class.upsert_from_transactional_model(m)
      expect(Suma::Analytics::Member.all).to be_empty
    end

    it "noops if models is empty" do
      expect { described_class.upsert_from_transactional_model([]) }.to_not raise_error
    end

    it "sets the current language while upserting and pulls it from a translated text field" do
      m = Suma::Fixtures.book_transaction.create
      m.memo.update(en: "this is the memo")
      described_class.upsert_from_transactional_model(m)
      expect(Suma::Analytics::BookTransaction.all).to contain_exactly(
        have_attributes(memo: "this is the memo"),
      )
    end
  end

  describe "destroy_from_transactional_model" do
    it "destroys rows related to the identified model" do
      m = Suma::Fixtures.member.create
      described_class.upsert_from_transactional_model(m)
      expect(Suma::Analytics::Member.all).to have_length(1)
      described_class.destroy_from_transactional_model(m.class, m.id)
      expect(Suma::Analytics::Member.all).to be_empty
    end
  end

  describe "truncate_all" do
    it "deletes all analytics rows" do
      Suma::Fixtures.order.create
      described_class.reimport_all
      expect(Suma::Analytics::Member.all).to have_length(1)
      expect(Suma::Analytics::Order.all).to have_length(1)
      described_class.truncate_all
      expect(Suma::Analytics::Member.all).to be_empty
      expect(Suma::Analytics::Order.all).to be_empty
    end
  end

  describe "reimport_all" do
    it "upserts rows for all relevant transactional models" do
      Suma::Fixtures.order.create
      Suma::Fixtures.order.create
      described_class.reimport_all
      expect(Suma::Analytics::Member.all).to have_length(2)
      expect(Suma::Analytics::Order.all).to have_length(2)
    end

    it "can specify oltp models" do
      Suma::Fixtures.order.create
      Suma::Fixtures.order.create
      described_class.reimport_all(oltp_classes: Suma::Member)
      expect(Suma::Analytics::Member.all).to have_length(2)
      expect(Suma::Analytics::Order.all).to have_length(0)
    end

    it "can specify olap models" do
      Suma::Fixtures.order.create
      Suma::Fixtures.order.create
      described_class.reimport_all(olap_classes: Suma::Analytics::Order)
      expect(Suma::Analytics::Member.all).to have_length(0)
      expect(Suma::Analytics::Order.all).to have_length(2)
    end

    it "can reimport a specific olap model" do
      Suma::Fixtures.order.create
      Suma::Analytics::Order.reimport
      expect(Suma::Analytics::Member.all).to have_length(0)
      expect(Suma::Analytics::Order.all).to have_length(1)
    end
  end

  describe "Member" do
    it "can denormalize a member" do
      o = Suma::Fixtures.member.create
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::Member.dataset.all).to contain_exactly(include(member_id: o.id, order_count: nil))
    end

    it "can denormalize an order" do
      o = Suma::Fixtures.order.create
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::Member.dataset.all).to contain_exactly(
        include(member_id: o.checkout.cart.member_id, order_count: 1),
      )
    end
  end

  describe "Order" do
    it "can denormalize an order" do
      o = Suma::Fixtures.order.create
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::Order.dataset.all).to contain_exactly(
        include(order_id: o.id, member_id: o.checkout.cart.member_id, funded_cost: 0),
      )
    end

    it "can denormalize into order items" do
      o = Suma::Fixtures.order.as_purchased_by.create
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::OrderItem.dataset.all).to contain_exactly(
        include(order_id: o.id),
      )
    end
  end

  describe "Ledger" do
    it "denormalizes from ledgers" do
      o = Suma::Fixtures.ledger.create
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::Ledger.dataset.all).to contain_exactly(
        include(ledger_id: o.id),
      )
    end
  end

  describe "BookTransaction" do
    it "denormalizes from book transactions" do
      o = Suma::Fixtures.book_transaction.create
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::BookTransaction.dataset.all).to contain_exactly(
        include(book_transaction_id: o.id),
      )
    end
  end

  describe "Charge" do
    it "denormalizes from charges" do
      o = Suma::Fixtures.charge.create
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::Charge.dataset.all).to contain_exactly(
        include(charge_id: o.id),
      )
    end
  end

  describe "FundingTransaction" do
    it "denormalizes from funding transactions" do
      o = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      o.strategy.set_response(:originating_instrument_label, "x-1234")
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::FundingTransaction.dataset.all).to contain_exactly(
        include(funding_transaction_id: o.id),
      )
    end

    it "works without an originated book transaction" do
      o = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      o.update(originated_book_transaction: nil)
      o.strategy.set_response(:originating_instrument_label, "x-1234")
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::FundingTransaction.dataset.all).to contain_exactly(
        include(funding_transaction_id: o.id),
      )
    end
  end

  describe "PayoutTransactions" do
    it "denormalizes from payout transactions" do
      o = Suma::Fixtures.payout_transaction.with_fake_strategy.create
      Suma::Analytics.upsert_from_transactional_model(o)
      expect(Suma::Analytics::PayoutTransaction.dataset.all).to contain_exactly(
        include(payout_transaction_id: o.id),
      )
    end
  end
end
