# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::Instrument", :db do
  let(:described_class) { Suma::Payment::Instrument }

  it_behaves_like "a payment instrument" do
    let(:instrument) do
      Suma::Fixtures.card.create
      Suma::Payment::Instrument.first
    end
  end

  it "is a view over bank accounts and cards" do
    ba = Suma::Fixtures.bank_account.create
    card = Suma::Fixtures.card.create
    expect(described_class.all).to contain_exactly(
      have_attributes(id: ba.id, payment_method_type: "bank_account"),
      have_attributes(id: card.id, payment_method_type: "card"),
    )
  end

  it "knows about expired and unexpired instruments" do
    exp = Suma::Fixtures.card.expired.create
    c = Suma::Fixtures.card.create
    ba = Suma::Fixtures.bank_account.create
    expect(described_class.dataset.expired_as_of(Time.now).all).to have_same_ids_as(exp)
    expect(described_class.dataset.unexpired_as_of(Time.now).all).to have_same_ids_as(c, ba)
  end

  it "can reify into concrete types" do
    ba = Suma::Fixtures.bank_account.create
    card = Suma::Fixtures.card.create
    rows = described_class.all
    expect(described_class.reify(rows)).to contain_exactly(
      be === ba,
      be === card,
    )
  end
end
