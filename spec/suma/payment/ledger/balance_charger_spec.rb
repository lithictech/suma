# frozen_string_literal: true

RSpec.describe Suma::Payment::Ledger::BalanceCharger, :db do
  let(:negative_member_account) {}
  let(:positive_member_account) { Suma::Fixtures.member.create.payment_account! }
  let(:ba) { Suma::Fixtures.bank_account.verified.member(member).create }
  let(:platform_account) { Suma::Payment::Account.lookup_platform_account }
  let(:platform_cash) { platform_account.ensure_cash_ledger }

  it "charges cash ledgers with negative balance", :i18n, reset_configuration: Suma::Payment do
    food = Suma::Fixtures.vendor_service_category.create(name: "food")

    platform_food = platform_account.ensure_ledger_with_category(food)

    account1 = Suma::Fixtures.payment_account.create
    account2 = Suma::Fixtures.payment_account.create
    account3 = Suma::Fixtures.payment_account.create
    account4 = Suma::Fixtures.payment_account.create
    account5 = Suma::Fixtures.payment_account.create
    [account1, account2, account3, account4, account5].each do |account|
      Suma::Fixtures.card.member(account.member).create
    end

    positive_cash = account1.ensure_cash_ledger
    negative_cash = account2.ensure_cash_ledger
    zero_cash = account3.ensure_cash_ledger
    negative_food = account4.ensure_ledger_with_category(food)
    # Skipped due to a balance above the grace threshold
    Suma::Payment.minimum_cash_balance_grace_cents = -75
    slightly_negative_cash = account3.ensure_cash_ledger

    Suma::Fixtures.book_transaction.from(platform_cash).to(positive_cash).create(amount: money("$5"))
    Suma::Fixtures.book_transaction.from(negative_cash).to(platform_cash).create(amount: money("$50"))
    Suma::Fixtures.book_transaction.from(negative_food).to(platform_food).create(amount: money("$500"))
    Suma::Fixtures.book_transaction.from(slightly_negative_cash).to(platform_cash).create(amount: money("$0.50"))

    Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.ready) do
      described_class.new.run
    end

    expect(Suma::Payment::FundingTransaction.all).to contain_exactly(
      have_attributes(amount: cost("$50"), originating_payment_account: be === negative_cash.account),
    )
  end

  it "skips failed collections", :i18n do
    account1 = Suma::Fixtures.payment_account.create
    Suma::Fixtures.card.member(account1.member).create
    account2 = Suma::Fixtures.payment_account.create

    # Skipped because the strategy is not ready
    account1_cash = account1.ensure_cash_ledger
    # Skipped since account2 has no instrument
    account2_cash = account2.ensure_cash_ledger

    Suma::Fixtures.book_transaction.from(account1_cash).to(platform_cash).create(amount: money("$10"))
    Suma::Fixtures.book_transaction.from(account2_cash).to(platform_cash).create(amount: money("$20"))

    Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.not_ready) do
      described_class.new.run
    end

    expect(Suma::Payment::FundingTransaction.all).to be_empty
  end

  it "tries all fundable instruments linked to the account, starting with the default instrument", :i18n do
    account = Suma::Fixtures.payment_account.create
    cash = account.ensure_cash_ledger

    member = account.member
    card1 = Suma::Fixtures.card.member(member).create
    card2 = Suma::Fixtures.card.member(member).create
    expired = Suma::Fixtures.card.member(member).expired.create
    deleted_card = Suma::Fixtures.card.member(member).create(soft_deleted_at: Time.now)
    bankacct = Suma::Fixtures.bank_account.member(member).verified.create
    unverified_ba = Suma::Fixtures.bank_account.member(member).create

    Suma::Fixtures.book_transaction.from(cash).to(platform_cash).create(amount: money("$10"))

    bc = described_class.new
    res = described_class::Result.new
    # Bank accounts end up first in the list as default; when we have explicit defaults this may need to change
    expect(bc).to receive(:charge_instrument).with(be === cash, be === bankacct).ordered.and_return(res)
    expect(bc).to receive(:charge_instrument).with(be === cash, be === card2).ordered.and_return(res)
    expect(bc).to receive(:charge_instrument).with(be === cash, be === card1).ordered.and_return(res)
    Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.not_ready) do
      bc.run
    end
    expect(Suma::Payment::FundingTransaction.all).to be_empty
  end

  describe "charge_balance_to" do
    let(:account) { Suma::Fixtures.payment_account.create }
    let(:cash) { account.ensure_cash_ledger }
    let(:member) { account.member }
    let(:card) { Suma::Fixtures.card.member(member).create }

    before(:each) do
      Suma::Fixtures.book_transaction.from(cash).to(platform_cash).create(amount: money("$10"))
    end

    it "noops if no account" do
      expect(described_class.charge_balance_to(nil, card)).to have_attributes(
        funding_transaction: nil, no_balance: true, error: nil,
      )
    end

    it "noops if cash ledger is not negative" do
      Suma::Payment::BookTransaction.dataset.delete
      account.refresh
      expect(described_class.charge_balance_to(account, card)).to have_attributes(
        funding_transaction: nil, no_balance: true, error: nil,
      )
    end

    it "charges the instrument", :i18n do
      fx = Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.ready) do
        described_class.charge_balance_to(account, card)
      end
      expect(fx).to have_attributes(
        funding_transaction: have_attributes(amount: cost("$10")),
        no_balance: false,
        error: nil,
      )
    end

    it "errors if the instrument cannot be used for funding" do
      ba = Suma::Fixtures.bank_account.member(member).create
      expect do
        described_class.charge_balance_to(account, ba)
      end.to raise_error(Suma::InvalidPrecondition, /cannot be used for funding/)
    end

    it "raises collection failures", :i18n do
      expect do
        Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.ready.failing) do
          described_class.charge_balance_to(account, card)
        end
      end.to raise_error(Suma::Payment::FundingTransaction::CollectFundsFailed)
    end
  end
end
