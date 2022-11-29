# frozen_string_literal: true

RSpec.describe "Suma::Payment::Ledger", :db do
  let(:described_class) { Suma::Payment::Ledger }
  describe "associations" do
    let(:ledger) { Suma::Fixtures.ledger.create }

    it "knows what it has originated and received" do
      Suma::Fixtures.book_transaction.create
      orig1 = Suma::Fixtures.book_transaction.from(ledger).create
      orig2 = Suma::Fixtures.book_transaction.from(ledger).create
      recip1 = Suma::Fixtures.book_transaction.to(ledger).create
      recip2 = Suma::Fixtures.book_transaction.to(ledger).create
      expect(ledger.originated_book_transactions).to have_same_ids_as(orig1, orig2)
      expect(ledger.received_book_transactions).to have_same_ids_as(recip1, recip2)
      expect(ledger.combined_book_transactions).to have_same_ids_as(orig1, orig2, recip1, recip2)
      # Test custom eager loader
      expect(ledger.account.ledgers.first.combined_book_transactions).to have_same_ids_as(orig1, orig2, recip1, recip2)
    end

    it "sorts combined transactions to have credits first" do
      now = Time.now
      debit1 = Suma::Fixtures.book_transaction.from(ledger).create(apply_at: now)
      debit2 = Suma::Fixtures.book_transaction.from(ledger).create(apply_at: now)
      credit1 = Suma::Fixtures.book_transaction.to(ledger).create(apply_at: now)
      credit2 = Suma::Fixtures.book_transaction.to(ledger).create(apply_at: now)
      expect(ledger.combined_book_transactions).to have_same_ids_as(debit1, debit2, credit1, credit2).ordered
      eager_ledger = ledger.account.ledgers.first
      expect(eager_ledger.combined_book_transactions).to have_same_ids_as(debit1, debit2, credit1, credit2).ordered
    end
  end

  describe "balance" do
    let(:ledger) { Suma::Fixtures.ledger.create }

    it "adds received and subtracts originated" do
      expect(ledger).to have_attributes(balance: cost("$0"))
      Suma::Fixtures.book_transaction.to(ledger).create(amount: money("$5"))
      Suma::Fixtures.book_transaction.to(ledger).create(amount: money("$10"))
      expect(ledger.refresh).to have_attributes(balance: cost("$15"))
      Suma::Fixtures.book_transaction.from(ledger).create(amount: money("$1.50"))
      Suma::Fixtures.book_transaction.from(ledger).create(amount: money("$1"))
      expect(ledger.refresh).to have_attributes(balance: cost("$12.50"))
    end
  end

  describe "can_be_used_to_purchase?" do
    it "is true if the service has a category in the ledger category chain" do
      food = Suma::Fixtures.vendor_service_category.create(name: 'food')
      grocery = Suma::Fixtures.vendor_service_category.create(name: 'grocery', parent: food)
      restaurant = Suma::Fixtures.vendor_service_category.create(name: 'restaurant', parent: food)
      organic = Suma::Fixtures.vendor_service_category.create(name: 'organic', parent: grocery)
      packaged = Suma::Fixtures.vendor_service_category.create(name: 'packaged', parent: grocery)

      mobility = Suma::Fixtures.vendor_service_category.create(name: 'mobility')
      scooters = Suma::Fixtures.vendor_service_category.create(name: 'scooter', parent: mobility)

      food_ledger = Suma::Fixtures.ledger.with_categories(food).create
      grocery_ledger = Suma::Fixtures.ledger.with_categories(grocery).create
      organic_ledger = Suma::Fixtures.ledger.with_categories(organic).create

      food_service = Suma::Fixtures.vendor_service.with_categories(food).create
      organic_service = Suma::Fixtures.vendor_service.with_categories(organic).create
      grocery_service = Suma::Fixtures.vendor_service.with_categories(grocery).create
      restaurant_service = Suma::Fixtures.vendor_service.with_categories(restaurant).create
      scooter_service = Suma::Fixtures.vendor_service.with_categories(scooters).create

      expect(food_ledger).to be_can_be_used_to_purchase(food_service)
      expect(food_ledger).to be_can_be_used_to_purchase(organic_service)
      expect(food_ledger).to be_can_be_used_to_purchase(restaurant_service)
      expect(food_ledger).to_not be_can_be_used_to_purchase(scooter_service)

      expect(grocery_ledger).to_not be_can_be_used_to_purchase(food_service)
      expect(grocery_ledger).to be_can_be_used_to_purchase(grocery_service)
      expect(grocery_ledger).to be_can_be_used_to_purchase(organic_service)
      expect(grocery_ledger).to_not be_can_be_used_to_purchase(restaurant_service)
      expect(grocery_ledger).to_not be_can_be_used_to_purchase(scooter_service)

      expect(organic_ledger).to_not be_can_be_used_to_purchase(food_service)
      expect(organic_ledger).to_not be_can_be_used_to_purchase(grocery_service)
      expect(organic_ledger).to be_can_be_used_to_purchase(organic_service)
      expect(organic_ledger).to_not be_can_be_used_to_purchase(restaurant_service)
      expect(organic_ledger).to_not be_can_be_used_to_purchase(scooter_service)

      expect(food_ledger.category_used_to_purchase(food_service)).to be === food
      expect(food_ledger.category_used_to_purchase(organic_service)).to be === food
      expect(food_ledger.category_used_to_purchase(restaurant_service)).to be === food
      expect(grocery_ledger.category_used_to_purchase(grocery_service)).to be === grocery
      expect(grocery_ledger.category_used_to_purchase(organic_service)).to be === grocery
    end

    it "can exclude categories from consideration" do
      cash = Suma::Fixtures.vendor_service_category.create(name: 'cash')
      food = Suma::Fixtures.vendor_service_category.create(name: 'food', parent: cash)
      promo = Suma::Fixtures.vendor_service_category.create(name: 'promo', parent: food)
      promo2 = Suma::Fixtures.vendor_service_category.create(name: 'promo2')

      cash_ledger = Suma::Fixtures.ledger.with_categories(cash).create
      promo_ledger = Suma::Fixtures.ledger.with_categories(promo).create
      promo_x2_ledger = Suma::Fixtures.ledger.with_categories(promo, promo2).create

      pcash_only = Suma::Fixtures.product.with_categories(cash).create
      ppromo_only = Suma::Fixtures.product.with_categories(promo).create
      pcash_and_promo = Suma::Fixtures.product.with_categories(cash, promo).create
      pcash_and_promo2 = Suma::Fixtures.product.with_categories(cash, promo2).create
      ppromo2 = Suma::Fixtures.product.with_categories(promo2).create

      expect(cash_ledger).to be_can_be_used_to_purchase(pcash_only)
      expect(cash_ledger).to be_can_be_used_to_purchase(pcash_and_promo)
      expect(cash_ledger).to be_can_be_used_to_purchase(ppromo_only)
      expect(cash_ledger).to be_can_be_used_to_purchase(pcash_and_promo2)
      expect(cash_ledger).to_not be_can_be_used_to_purchase(ppromo2)

      expect(cash_ledger).to_not be_can_be_used_to_purchase(pcash_only, exclude: [cash])
      expect(cash_ledger).to be_can_be_used_to_purchase(pcash_and_promo, exclude: [cash])
      expect(cash_ledger).to_not be_can_be_used_to_purchase(pcash_and_promo2, exclude: [cash])
      expect(cash_ledger).to_not be_can_be_used_to_purchase(ppromo2, exclude: [cash])

      expect(promo_ledger).to_not be_can_be_used_to_purchase(pcash_only)
      expect(promo_ledger).to be_can_be_used_to_purchase(pcash_and_promo)
      expect(promo_ledger).to be_can_be_used_to_purchase(ppromo_only)
      expect(promo_ledger).to_not be_can_be_used_to_purchase(pcash_and_promo2)
      expect(promo_ledger).to_not be_can_be_used_to_purchase(ppromo2)

      expect(promo_ledger).to_not be_can_be_used_to_purchase(pcash_only, exclude: [cash])
      expect(promo_ledger).to be_can_be_used_to_purchase(pcash_and_promo, exclude: [cash])
      expect(promo_ledger).to be_can_be_used_to_purchase(ppromo_only, exclude: [cash])
      expect(promo_ledger).to_not be_can_be_used_to_purchase(pcash_and_promo2, exclude: [cash])
      expect(promo_ledger).to_not be_can_be_used_to_purchase(ppromo2, exclude: [cash])
    end
  end

  describe "validations" do
    it "account and name must be unique" do
      Suma::Fixtures.ledger.create(name: "A")
      led = Suma::Fixtures.ledger.create(name: "A")
      expect do
        Suma::Fixtures.ledger(account: led.account).create(name: "A")
      end.to raise_error(Sequel::UniqueConstraintViolation)
    end
  end
end
