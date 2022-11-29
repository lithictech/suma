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

  describe "find_chargeable_ledgers" do
    let(:food) { Suma::Fixtures.vendor_service_category.create(name: "food") }
    let(:grocery) { Suma::Fixtures.vendor_service_category.create(name: "grocery", parent: food) }
    let(:mobility) { Suma::Fixtures.vendor_service_category.create(name: "mobility") }
    let(:grocery_service) { Suma::Fixtures.vendor_service.with_categories(grocery).create }
    let(:ledger_fac) { Suma::Fixtures.ledger(account:) }
    let(:calculation_context) { Suma::Payment::CalculationContext.new }
    let(:kw) { {now:, calculation_context:} }

    it "raises if there are no ledgers" do
      expect do
        account.find_chargeable_ledgers(grocery_service, money("$6"), **kw)
      end.to raise_error(Suma::InvalidPrecondition, /has no ledgers/)
    end

    it "raises if the amount is negative" do
      expect do
        account.find_chargeable_ledgers(grocery_service, money("-$1"), **kw)
      end.to raise_error(ArgumentError, /cannot be negative/)
    end

    it "raises if the required total cannot be reached" do
      can_use = ledger_fac.with_categories(food).create
      cannot_use = ledger_fac.with_categories(mobility).create
      Suma::Fixtures.book_transaction.to(can_use).create(amount: money("$5"))
      Suma::Fixtures.book_transaction.to(cannot_use).create(amount: money("$50"))
      expect do
        account.find_chargeable_ledgers(grocery_service, money("$6"), **kw)
      end.to raise_error(Suma::Payment::InsufficientFunds)
    end

    it "assigns the negative remainder to the given ledger" do
      cannot_use = ledger_fac.with_categories(mobility).create
      ledgers = Array.new(3) { ledger_fac.with_categories(grocery).create }
      Suma::Fixtures.book_transaction.to(ledgers[0]).create(amount: money("$6"))
      results = account.find_chargeable_ledgers(grocery_service, money("10"), remainder_ledger: ledgers[1], **kw)
      expect(results).to contain_exactly(
        have_attributes(ledger: be === ledgers[0], amount: cost("$6")),
        have_attributes(ledger: be === ledgers[1], amount: cost("$4")),
        have_attributes(ledger: be === ledgers[2], amount: cost("$0")),
      )
    end

    it "can dynamically choose the remainder ledger with :last or :first" do
      cannot_use = ledger_fac.with_categories(mobility).create
      ledgers = Array.new(3) { ledger_fac.with_categories(grocery).create }
      Suma::Fixtures.book_transaction.to(ledgers[1]).create(amount: money("$6"))
      results = account.find_chargeable_ledgers(grocery_service, money("10"), remainder_ledger: :last, **kw)
      expect(results).to contain_exactly(
        have_attributes(ledger: be === ledgers[0], amount: cost("$0")),
        have_attributes(ledger: be === ledgers[1], amount: cost("$6")),
        have_attributes(ledger: be === ledgers[2], amount: cost("$4")),
      )
    end

    it "can use :ignore as the remainder" do
      ledgers = Array.new(3) { ledger_fac.with_categories(grocery).create }
      Suma::Fixtures.book_transaction.to(ledgers[1]).create(amount: money("$6"))
      results = account.find_chargeable_ledgers(grocery_service, money("10"), remainder_ledger: :ignore, **kw)
      expect(results).to contain_exactly(
        have_attributes(ledger: be === ledgers[0], amount: cost("$0")),
        have_attributes(ledger: be === ledgers[1], amount: cost("$6")),
        have_attributes(ledger: be === ledgers[2], amount: cost("$0")),
      )
    end

    it "can :return the remainder" do
      ledgers = Array.new(3) { ledger_fac.with_categories(grocery).create }
      Suma::Fixtures.book_transaction.to(ledgers[1]).create(amount: money("$6"))
      results = account.find_chargeable_ledgers(grocery_service, money("10"), remainder_ledger: :return, **kw)
      expect(results).to contain_exactly(
        have_attributes(ledger: be === ledgers[0], amount: cost("$0")),
        have_attributes(ledger: be === ledgers[1], amount: cost("$6")),
        have_attributes(ledger: be === ledgers[2], amount: cost("$0")),
        have_attributes(ledger: nil, amount: cost("$4")),
      )
    end

    it "errors if there are no contributions and a remainder ledger is dynamic" do
      ledger_fac.create
      svc = Suma::Fixtures.vendor_service.create
      expect do
        account.find_chargeable_ledgers(svc, money("$6"), remainder_ledger: :last, **kw)
      end.to raise_error(Suma::InvalidPrecondition, /No ledgers for charge/)
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
      results = account.find_chargeable_ledgers(grocery_service, money("$22"), **kw)
      expect(results).to contain_exactly(
        have_attributes(ledger: be === can_use_g1, amount: cost("$10"), apply_at: match_time(now)),
        have_attributes(ledger: be === can_use_g2, amount: cost("$10")),
        have_attributes(ledger: be === can_use_f, amount: cost("$2")),
      )
    end

    it "returns the first matching ledger for $0" do
      cannot_use = ledger_fac.with_categories(mobility).create
      can_use_g1 = ledger_fac.with_categories(grocery).create
      Suma::Fixtures.book_transaction.to(cannot_use).create(amount: money("$50"))
      Suma::Fixtures.book_transaction.to(can_use_g1).create(amount: money("$10"))
      results = account.find_chargeable_ledgers(grocery_service, money("$0"), **kw)
      expect(results).to contain_exactly(
        have_attributes(ledger: be === can_use_g1, amount: cost("$0"), apply_at: match_time(now)),
      )
    end

    it "raises if the remainder ledger is needed, but not allowed for contributions" do
      led = ledger_fac.create
      svc = Suma::Fixtures.vendor_service.create
      expect do
        account.find_chargeable_ledgers(svc, money("$6"), remainder_ledger: led, **kw)
      end.to raise_error(Suma::InvalidPrecondition, /not valid for charge contributions/)
    end

    it "can exclude ledgers which have a subset of some excluded categories" do
      parent = Suma::Fixtures.vendor_service_category.create
      vcash1 = Suma::Fixtures.vendor_service_category.create(name: "cash1", parent:)
      vcash2parent = Suma::Fixtures.vendor_service_category.create(name: "cash2parent", parent:)
      vcash2child = Suma::Fixtures.vendor_service_category.create(name: "cash2child", parent: vcash2parent)
      cash1 = ledger_fac.with_categories(vcash1).create
      cash2 = ledger_fac.with_categories(vcash2child).create
      cash12 = ledger_fac.with_categories(vcash1, vcash2child).create

      product = Suma::Fixtures.product.with_categories(vcash1, vcash2child).create

      results = account.find_chargeable_ledgers(
        product, money("10"), remainder_ledger: :ignore, **kw,
      )
      expect(results).to contain_exactly(
        have_attributes(ledger: be === cash1),
        have_attributes(ledger: be === cash2),
        have_attributes(ledger: be === cash12),
      )

      results = account.find_chargeable_ledgers(
        product, money("10"), remainder_ledger: :ignore, exclude_up: [parent], **kw,
      )
      expect(results).to contain_exactly(
        have_attributes(ledger: be === cash1),
        have_attributes(ledger: be === cash2),
        have_attributes(ledger: be === cash12),
      )

      results = account.find_chargeable_ledgers(
        product, money("10"), remainder_ledger: :ignore, exclude_up: [vcash1], **kw,
      )
      expect(results).to contain_exactly(
        have_attributes(ledger: be === cash2),
        have_attributes(ledger: be === cash12),
      )

      results = account.find_chargeable_ledgers(
        product, money("10"), remainder_ledger: :ignore, exclude_up: [vcash2parent], **kw,
      )
      expect(results).to contain_exactly(
        have_attributes(ledger: be === cash1),
        have_attributes(ledger: be === cash2),
        have_attributes(ledger: be === cash12),
      )

      results = account.find_chargeable_ledgers(
        product, money("10"), remainder_ledger: :ignore, exclude_up: [vcash2child], **kw,
      )
      expect(results).to contain_exactly(
        have_attributes(ledger: be === cash1),
        have_attributes(ledger: be === cash12),
      )

      results = account.find_chargeable_ledgers(
        product, money("10"), remainder_ledger: :ignore, exclude_up: [vcash1, vcash2child], **kw,
      )
      expect(results).to be_empty
    end
  end

  describe "debit_contributions" do
    let(:food) { Suma::Fixtures.vendor_service_category.create(name: "food") }
    let(:grocery) { Suma::Fixtures.vendor_service_category.create(name: "grocery", parent: food) }
    let(:grocery_service) { Suma::Fixtures.vendor_service.with_categories(grocery).create }
    let(:ledger_fac) { Suma::Fixtures.ledger(account:) }
    let(:calculation_context) { Suma::Payment::CalculationContext.new }

    it "debits contributions as specified", :lang do
      ledgers = Array.new(3) { ledger_fac.with_categories(food).create }
      ledgers.each { |led| Suma::Fixtures.book_transaction(amount: money("$2")).to(led).create }
      contribs = account.find_chargeable_ledgers(grocery_service, money("$6"), now:, calculation_context:)
      results = account.debit_contributions(contribs, memo: translated_text("hi"))
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
end
