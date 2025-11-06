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
      have_attributes(instrument_id: ba.id, payment_method_type: "bank_account"),
      have_attributes(instrument_id: card.id, payment_method_type: "card"),
    )
  end

  it "knows about expired and unexpired instruments" do
    exp = Suma::Fixtures.card.expired.create
    c = Suma::Fixtures.card.create
    ba = Suma::Fixtures.bank_account.create
    expect(described_class.dataset.expired_as_of(Time.now).all).to contain_exactly(
      have_attributes(instrument_id: exp.id, payment_method_type: "card"),
    )
    expect(described_class.dataset.unexpired_as_of(Time.now).all).to contain_exactly(
      have_attributes(instrument_id: c.id, payment_method_type: "card"),
      have_attributes(instrument_id: ba.id, payment_method_type: "bank_account"),
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

  it "can query concrete types" do
    ba = Suma::Fixtures.bank_account.create
    expect(described_class.for("bank_account", ba.id).first).to have_attributes(
      payment_method_type: "bank_account", instrument_id: ba.id,
    )
    expect(described_class.for("card", ba.id).first).to be_nil
  end

  describe "::post_create_cleanup" do
    let(:member) { Suma::Fixtures.member.create }
    let(:now) { Time.now }

    it "soft deletes all expired instruments" do
      e = Suma::Fixtures.card.member(member).expired.create
      t = 5.hours.ago
      d = Suma::Fixtures.card.member(member).create(soft_deleted_at: t)
      c = Suma::Fixtures.card.member(member).create
      described_class.post_create_cleanup(c, now:)
      expect(e.refresh).to be_soft_deleted
      expect(d.refresh).to have_attributes(soft_deleted_at: match_time(t))
    end
  end
end
