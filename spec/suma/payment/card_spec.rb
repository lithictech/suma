# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::Card", :db do
  let(:described_class) { Suma::Payment::Card }

  it_behaves_like "a payment instrument"

  it "knows when it is usable for funding and payouts" do
    c = Suma::Fixtures.card.create
    now = Time.now
    expect(c).to be_usable_for_funding(now:)
    expect(c).to_not be_usable_for_payout(now:)
    expect(described_class.usable_for_funding(now:).all).to have_same_ids_as(c)
    expect(described_class.usable_for_payout(now:).all).to be_empty

    c.update(stripe_json: c.stripe_json.merge("exp_year" => 1001))
    expect(c).to_not be_usable_for_funding(now:)
    expect(c).to_not be_usable_for_payout(now:)
    expect(described_class.usable_for_funding(now:).all).to be_empty
    expect(described_class.usable_for_payout(now:).all).to be_empty
  end

  it "knows its expiration" do
    t = Time.now
    c = Suma::Fixtures.card.expired(month: 5, year: 3001).create
    expect(c).to have_attributes(expires_at: match_time("3001-06-01T00:00:00Z"))
    expect(c).to_not be_expired(now: Time.now)
    expect(described_class.expired_as_of(t).all).to be_empty
    expect(described_class.unexpired_as_of(t).all).to have_same_ids_as(c)
    c.update(stripe_json: c.stripe_json.merge("exp_year" => 1001))
    expect(c).to have_attributes(expires_at: match_time("1001-06-01T00:00:00Z"))
    expect(c).to be_expired(now: t)
    expect(described_class.expired_as_of(t).all).to have_same_ids_as(c)
    expect(described_class.unexpired_as_of(t).all).to be_empty
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
        have_attributes(name: "Stripe Customer", url: "https://dashboard.stripe.com/customers/cu_123"),
      )
    end
  end
end
