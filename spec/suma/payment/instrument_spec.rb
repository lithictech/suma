# frozen_string_literal: true

RSpec.describe "Suma::Payment::Instrument", :db do
  let(:described_class) { Suma::Payment::Instrument }

  it "is a view over bank accounts and cards" do
    ba = Suma::Fixtures.bank_account.create
    card = Suma::Fixtures.card.create
    expect(described_class.all).to contain_exactly(
      have_attributes(id: ba.id, type: "bank_account", usable_for_funding?: false, usable_for_payout?: true),
      have_attributes(id: card.id, type: "card", usable_for_funding?: true, usable_for_payout?: false),
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
