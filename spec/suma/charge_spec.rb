# frozen_string_literal: true

RSpec.describe "Suma::Charge", :db do
  let(:described_class) { Suma::Charge }

  describe "associations" do
    it "is associated with book transactions" do
      ch = Suma::Fixtures.charge.create
      bx = Suma::Fixtures.book_transaction.create
      ch.add_contributing_book_transaction(bx)
      expect(ch.contributing_book_transactions).to have_same_ids_as(bx)
      expect(bx.charge_contributed_to).to be === ch
    end
  end

  describe "validations" do
    it "requires a trip or order" do
      c = Suma::Charge.new(member: Suma::Fixtures.member.create, undiscounted_subtotal: "$1")
      expect { c.save_changes }.to raise_error(Sequel::CheckConstraintViolation)
    end
  end
end
