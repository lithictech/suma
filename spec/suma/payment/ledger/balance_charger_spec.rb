# frozen_string_literal: true

require "suma/payment/ledger/balance_charger"

RSpec.describe Suma::Payment::Ledger::BalanceCharger, :db do
  let(:negative_member_account) {}
  let(:positive_member_account) { Suma::Fixtures.member.create.payment_account! }
  let(:ba) { Suma::Fixtures.bank_account.verified.member(member).create }
  let(:platform_account) { Suma::Payment::Account.lookup_platform_account }
  let(:platform_cash) { platform_account.ensure_cash_ledger }

  it "charges cash ledgers with negative balance", :i18n do
    food = Suma::Fixtures.vendor_service_category.create(name: "food")

    platform_food = platform_account.ensure_ledger_with_category(food)

    account1 = Suma::Fixtures.payment_account.create
    account2 = Suma::Fixtures.payment_account.create
    account3 = Suma::Fixtures.payment_account.create
    account4 = Suma::Fixtures.payment_account.create
    [account1, account2, account3, account4].each do |account|
      Suma::Fixtures.card.member(account.member).create
    end

    positive_cash = account1.ensure_cash_ledger
    negative_cash = account2.ensure_cash_ledger
    zero_cash = account3.ensure_cash_ledger
    negative_food = account4.ensure_ledger_with_category(food)

    Suma::Fixtures.book_transaction.from(platform_cash).to(positive_cash).create(amount: money("$5"))
    Suma::Fixtures.book_transaction.from(negative_cash).to(platform_cash).create(amount: money("$50"))
    Suma::Fixtures.book_transaction.from(negative_food).to(platform_food).create(amount: money("$500"))

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

  it "tries all cards linked to the account, starting with the default instrument", :i18n do
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
end
