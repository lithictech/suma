# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::Card", :db do
  let(:described_class) { Suma::Payment::Card }

  it_behaves_like "a payment instrument" do
    let(:instrument) { Suma::Fixtures.card.create }
  end

  describe "institution" do
    it "uses a known branch" do
      expect(Suma::Fixtures.card.visa.create.institution).to have_attributes(
        name: "Visa",
        color: "#1A1F71",
        logo: end_with("5ErkJggg=="),
      )
    end

    it "falls back to an unknown brand" do
      expect(Suma::Fixtures.card.with_helcim({"cardType" => "foo"}).create.institution).to have_attributes(
        name: "foo",
        color: "#AAAAAA",
        logo: end_with("ElFTkSuQmCC"),
      )
    end
  end
end
