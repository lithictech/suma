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
        logo_src: end_with("5ErkJggg=="),
      )
    end

    it "falls back to an unknown brand" do
      expect(Suma::Fixtures.card.with_stripe({"brand" => "foo"}).create.institution).to have_attributes(
        name: "foo",
        color: "#AAAAAA",
        logo_src: end_with("ElFTkSuQmCC"),
      )
    end
  end

  describe "external links" do
    it "links to the Stripe dashboard" do
      ca = Suma::Fixtures.card.with_stripe({"customer" => "cu_123"}).create
      expect(ca.external_links).to contain_exactly(
        {name: "Stripe Customer", url: "https://dashboard.stripe.com/customers/cu_123"},
      )
    end
  end
end
