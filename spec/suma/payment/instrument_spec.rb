# frozen_string_literal: true

RSpec.describe "Suma::Payment::Instrument", :db do
  let(:described_class) { Suma::Payment::Instrument }

  it "is a view over bank accounts and cards" do
    ba = Suma::Fixtures.bank_account.create
    card = Suma::Fixtures.card.create
    expect(described_class.naked.all).to contain_exactly(
      include(id: ba.id, type: "bank_account"),
      include(id: card.id, type: "card"),
    )
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
