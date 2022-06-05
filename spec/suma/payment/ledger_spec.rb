# frozen_string_literal: true

RSpec.describe "Suma::Payment::Ledger", :db do
  let(:described_class) { Suma::Payment::Ledger }
  describe "associations" do
    let(:ledger) { Suma::Fixtures.ledger.create }

    it "knows what it has originated and received" do
      Suma::Fixtures.book_transaction.create
      orig = Suma::Fixtures.book_transaction.from(ledger).create
      recip = Suma::Fixtures.book_transaction.to(ledger).create
      expect(ledger.originated_book_transactions).to have_same_ids_as(orig)
      expect(ledger.received_book_transactions).to have_same_ids_as(recip)
      expect(ledger.combined_book_transactions).to have_same_ids_as(orig, recip)
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
      food = Suma::Fixtures.vendor_service_category.create
      grocery = Suma::Fixtures.vendor_service_category.create(parent: food)
      restaurant = Suma::Fixtures.vendor_service_category.create(parent: food)
      organic = Suma::Fixtures.vendor_service_category.create(parent: grocery)
      packaged = Suma::Fixtures.vendor_service_category.create(parent: grocery)

      mobility = Suma::Fixtures.vendor_service_category.create
      scooters = Suma::Fixtures.vendor_service_category.create(parent: mobility)

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
      expect(organic_ledger.category_used_to_purchase(organic_service)).to be === organic
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
