# frozen_string_literal: true

RSpec.describe "Suma::Charge", :db do
  let(:described_class) { Suma::Charge }

  describe "line items" do
    it "returns line items with book transactions" do
      charge = Suma::Fixtures.charge.create
      li1 = charge.add_line_item(book_transaction: Suma::Fixtures.book_transaction.create)
      li2 = charge.add_line_item(book_transaction: Suma::Fixtures.book_transaction.create)
      amount = Money.new(350)
      memo = Suma::Fixtures.translated_text.create
      li3 = Suma::Charge::LineItem.create_self(charge:, amount:, memo:)
      li4 = Suma::Charge::LineItem.create_self(charge:, amount:, memo:)
      expect(charge.line_items).to have_length(4)
      expect(charge.on_platform_line_items).to contain_exactly(be === li1, be === li2)
      expect(charge.off_platform_line_items).to contain_exactly(be === li3, be === li4)
    end
  end

  describe "Suma::Charge::LineItem" do
    let(:described_class) { Suma::Charge::LineItem }

    let(:charge) { Suma::Fixtures.charge.create }
    let(:book_transaction) { Suma::Fixtures.book_transaction.create }
    let(:memo) { Suma::Fixtures.translated_text.create }

    it "requires self data to be set if not using a book transaction" do
      li = described_class.create_self(charge:, amount: Money.new(500), memo:)
      expect { li.update(book_transaction:) }.to raise_error(Sequel::CheckConstraintViolation)
      described_class.create(charge:, book_transaction:)
    end

    it "has an association from SelfData to LineItem" do
      li = described_class.create_self(charge:, amount: Money.new(500), memo:)
      expect(li.self_data.line_item).to be === li
    end

    it "can be fixtured" do
      Suma::Fixtures.charge_line_item.create
      Suma::Fixtures.charge_line_item.self_data.create
      Suma::Fixtures.charge_line_item.book_transaction.create
    end
  end
end
