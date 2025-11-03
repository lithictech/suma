# frozen_string_literal: true

RSpec.describe "Suma::Payment::Account", :db do
  let(:described_class) { Suma::Payment::Account }
  let(:account) { Suma::Fixtures.payment_account.create }
  let(:member) { account.member }
  let(:now) { Time.now }

  describe "associations" do
    it "can find its cash ledger" do
      acct = Suma::Fixtures.payment_account.create
      expect(acct.cash_ledger).to be_nil
      expect { acct.cash_ledger! }.to raise_error(/has no cash ledger/)
      cashledger = Suma::Payment.ensure_cash_ledger(acct.member)
      expect(acct.refresh.cash_ledger).to be_a(Suma::Payment::Ledger)
      expect(acct.cash_ledger).to be === cashledger
    end

    it "can find book transactions across all ledgers" do
      acct = Suma::Fixtures.payment_account.create
      led1 = Suma::Fixtures.ledger(account: acct).create
      led2 = Suma::Fixtures.ledger(account: acct).create
      x1 = Suma::Fixtures.book_transaction.from(led1).create
      x2 = Suma::Fixtures.book_transaction.to(led1).create
      x3 = Suma::Fixtures.book_transaction.to(led2).create
      expect(acct.all_book_transactions).to have_same_ids_as(x1, x2, x3)
    end
  end

  describe "validations" do
    it "must have an owner" do
      pa = account
      pa.member = nil
      expect { pa.save_changes }.to raise_error(Sequel::CheckConstraintViolation)
    end

    it "can have only one platform account" do
      Suma::Fixtures.payment_account.create
      pa2 = Suma::Fixtures.payment_account.create
      described_class.lookup_platform_account
      expect do
        pa2.update(member: nil, is_platform_account: true)
      end.to raise_error(Sequel::UniqueConstraintViolation, /one_platform_account/)
    end
  end

  describe "total_balance" do
    it "sums ledgers" do
      expect(account.total_balance).to cost("$0")
      ledger1 = Suma::Fixtures.ledger(account:).create
      ledger2 = Suma::Fixtures.ledger(account:).create
      Suma::Fixtures.book_transaction.to(ledger1).create(amount: money("$5"))
      Suma::Fixtures.book_transaction.to(ledger2).create(amount: money("$10"))
      expect(account.total_balance).to cost("$15")
    end
  end

  describe "calculate_charge_contributions" do
    let(:food) { Suma::Fixtures.vendor_service_category.create(name: "food") }
    let(:grocery) { Suma::Fixtures.vendor_service_category.create(name: "grocery", parent: food) }
    let(:mobility) { Suma::Fixtures.vendor_service_category.create(name: "mobility") }
    let(:grocery_service) { Suma::Fixtures.vendor_service.with_categories(grocery).create }
    let(:ledger_fac) { Suma::Fixtures.ledger(account:) }
    let(:context) { Suma::Payment::CalculationContext.new(now) }
    let!(:cash_ledger) { account.ensure_cash_ledger }

    it "raises if there is no cash ledger" do
      cash_ledger.remove_all_vendor_service_categories
      cash_ledger.destroy
      expect do
        account.calculate_charge_contributions(context, grocery_service, money("$6"))
      end.to raise_error(Suma::InvalidPrecondition, /has no cash ledger/)
    end

    it "raises if the amount is negative" do
      expect do
        account.calculate_charge_contributions(context, grocery_service, money("-$1"))
      end.to raise_error(ArgumentError, /cannot be negative/)
    end

    it "uses the cash ledger for what is not covered by subledgers" do
      cannot_use = ledger_fac.with_categories(mobility).create
      ledgers = Array.new(3) { ledger_fac.with_categories(grocery).create }
      Suma::Fixtures.book_transaction.to(ledgers[0]).create(amount: money("$6"))
      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$10"))
      results = account.calculate_charge_contributions(context, grocery_service, money("10"))
      expect(results.cash).to have_attributes(ledger: cash_ledger, amount: cost("$4"))
      expect(results.remainder).to cost("$0")
      expect(results.rest).to contain_exactly(
        have_attributes(ledger: be === ledgers[0], amount: cost("$6")),
        have_attributes(ledger: be === ledgers[1], amount: cost("$0")),
        have_attributes(ledger: be === ledgers[2], amount: cost("$0")),
      )
    end

    it "returns the remainder" do
      ledgers = Array.new(3) { ledger_fac.with_categories(grocery).create }
      Suma::Fixtures.book_transaction.to(ledgers[1]).create(amount: money("$6"))
      results = account.calculate_charge_contributions(context, grocery_service, money("10"))
      expect(results.cash).to have_attributes(ledger: cash_ledger, amount: cost("$0"))
      expect(results.remainder).to cost("$4")
      expect(results.rest).to contain_exactly(
        have_attributes(ledger: be === ledgers[0], amount: cost("$0")),
        have_attributes(ledger: be === ledgers[1], amount: cost("$6")),
        have_attributes(ledger: be === ledgers[2], amount: cost("$0")),
      )
    end

    it "returns the right amount for suitable ledgers" do
      can_use_g1 = ledger_fac.with_categories(grocery).create
      can_use_f = ledger_fac.with_categories(food).create
      can_use_g2 = ledger_fac.with_categories(grocery).create
      cannot_use = ledger_fac.with_categories(mobility).create
      Suma::Fixtures.book_transaction.to(cannot_use).create(amount: money("$50"))
      Suma::Fixtures.book_transaction.to(can_use_g1).create(amount: money("$10"))
      Suma::Fixtures.book_transaction.to(can_use_f).create(amount: money("$10"))
      Suma::Fixtures.book_transaction.to(can_use_g2).create(amount: money("$10"))
      results = account.calculate_charge_contributions(context, grocery_service, money("$22"))
      expect(results.cash).to have_attributes(ledger: cash_ledger, amount: cost("$0"))
      expect(results.remainder).to cost("$0")
      expect(results.rest).to contain_exactly(
        have_attributes(ledger: be === can_use_g1, amount: cost("$10"), apply_at: match_time(now)),
        have_attributes(ledger: be === can_use_g2, amount: cost("$10")),
        have_attributes(ledger: be === can_use_f, amount: cost("$2")),
      )
    end

    it "returns $0 amounts for $0" do
      cannot_use = ledger_fac.with_categories(mobility).create
      can_use_g1 = ledger_fac.with_categories(grocery).create
      Suma::Fixtures.book_transaction.to(cannot_use).create(amount: money("$50"))
      Suma::Fixtures.book_transaction.to(can_use_g1).create(amount: money("$10"))
      results = account.calculate_charge_contributions(context, grocery_service, money("$0"))
      expect(results.cash).to have_attributes(ledger: cash_ledger, amount: cost("$0"))
      expect(results.remainder).to cost("$0")
      expect(results.rest).to contain_exactly(
        have_attributes(ledger: be === can_use_g1, amount: cost("$0"), apply_at: match_time(now)),
      )
    end
  end

  describe "debit_contributions" do
    let(:food) { Suma::Fixtures.vendor_service_category.create(name: "food") }
    let(:grocery) { Suma::Fixtures.vendor_service_category.create(name: "grocery", parent: food) }
    let(:grocery_service) { Suma::Fixtures.vendor_service.with_categories(grocery).create }
    let(:ledger_fac) { Suma::Fixtures.ledger(account:) }
    let(:context) { Suma::Payment::CalculationContext.new(now) }
    let!(:cash_ledger) { account.ensure_cash_ledger }

    it "debits contributions as specified", :lang do
      ledgers = Array.new(3) { ledger_fac.with_categories(food).create }
      ledgers.each { |led| Suma::Fixtures.book_transaction(amount: money("$2")).to(led).create }
      contribs = account.calculate_charge_contributions(context, grocery_service, money("$6"))
      results = account.debit_contributions(contribs.all.select(&:amount?), memo: translated_text("hi"))
      expect(results).to all(be_a(Suma::Payment::BookTransaction))
      recip = Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(food)
      expect(results).to contain_exactly(
        have_attributes(
          originating_ledger: be === ledgers[0],
          receiving_ledger: be === recip,
          associated_vendor_service_category: be === food,
          amount: cost("$2"),
        ),
        have_attributes(
          originating_ledger: be === ledgers[1],
          receiving_ledger: be === recip,
          associated_vendor_service_category: be === food,
          amount: cost("$2"),
        ),
        have_attributes(
          originating_ledger: be === ledgers[2],
          receiving_ledger: be === recip,
          associated_vendor_service_category: be === food,
          amount: cost("$2"),
        ),
      )
    end
  end

  describe "platform account" do
    it "can be looked up" do
      pa = described_class.lookup_platform_account
      expect(pa).to have_attributes(
        member: nil,
        vendor: nil,
        is_platform_account: true,
      )
      pa2 = described_class.lookup_platform_account
      expect(pa2).to be === pa
    end

    it "can ensure a distinct ledger for a category" do
      pa = described_class.lookup_platform_account
      cat1 = Suma::Fixtures.vendor_service_category.create(name: "Cat1")
      cat2 = Suma::Fixtures.vendor_service_category.create
      led = described_class.lookup_platform_vendor_service_category_ledger(cat1)
      expect(led).to have_attributes(account: be === pa, name: "Cat1")
      expect(led.vendor_service_categories).to contain_exactly(be === cat1)
      expect(described_class.lookup_platform_vendor_service_category_ledger(cat1)).to be === led
      expect(described_class.lookup_platform_vendor_service_category_ledger(cat2)).to_not be === led
    end
  end

  describe "admin helpers" do
    it "can display member, vendor, and platform names and links" do
      account.set(member:, vendor: nil, is_platform_account: false)
      expect(account).to have_attributes(
        admin_link: "http://localhost:22014/member/#{member.id}",
        display_name: member.name,
      )

      vendor = Suma::Fixtures.vendor.create
      account.set(member: nil, vendor:, is_platform_account: false)
      expect(account).to have_attributes(
        admin_link: "http://localhost:22014/vendor/#{vendor.id}",
        display_name: vendor.name,
      )

      account.set(member: nil, vendor: nil, is_platform_account: true)
      expect(account).to have_attributes(
        admin_link: "http://localhost:22014/payment-accounts/platform",
        display_name: "Suma Platform",
      )

      account.set(member: nil, vendor: nil, is_platform_account: false)
      expect(account).to have_attributes(
        admin_link: "http://localhost:22014/payment-accounts/#{account.id}",
        display_name: "Payment Account #{account.id}",
      )
    end
  end

  describe "HasAccount mixin" do
    it "finds the payment account" do
      m = Suma::Fixtures.member.create
      expect { m.payment_account! }.to raise_error(/does not have a payment_account/)
      led = Suma::Payment.ensure_cash_ledger(m)
      expect(m.refresh.payment_account!).to be === led.account
    end
  end
end
