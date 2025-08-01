# frozen_string_literal: true

RSpec.describe Suma::Organization::Membership::Verification::DuplicateFinder, :db do
  let(:member_name) { "Rob Galanakis" }
  let(:phone) { "15552345678" }
  let(:email) { "a@b.c" }
  let(:address) do
    Suma::Address.create(
      address1: "123 Main St",
      address2: "Apt 5",
      city: "Portland",
      state_or_province: "OR",
      postal_code: "97215",
    )
  end
  let(:member) do
    m = Suma::Fixtures.member.create(name: member_name, phone:, email:)
    m.legal_entity.update(address: address)
    m
  end
  let(:org_name) { "SNAP/WIC" }
  let(:org) { Suma::Fixtures.organization.create(name: org_name) }
  let(:membership) { Suma::Fixtures.organization_membership.unverified(org_name).create(member:) }
  let!(:verification) { membership.verification }
  let(:finder) { described_class.new(verification) }

  def run = finder.run.matches.map { |m| m.as_serialized.as_json }

  describe "run" do
    it "finds members with duplicate account numbers (on a verified membership)" do
      member2 = Suma::Fixtures.member.create
      membership2 = Suma::Fixtures.organization_membership.verified(org).create(member: member2)
      verification2 = Suma::Fixtures.organization_membership_verification.create(membership: membership2)
      verification2.update(account_number: "123abc")
      verification.update(account_number: "123abc")
      expect(run).to contain_exactly(
        include(
          "factors" => [{"reason" => "account_number", "risk" => {"name" => "high", "value" => 1}}],
          "member_id" => member2.id,
        ),
      )
    end

    it "finds members with duplicate account numbers (on an unverified membership)" do
      member2 = Suma::Fixtures.member.create
      membership2 = Suma::Fixtures.organization_membership.unverified(org.name).create(member: member2)
      verification2 = membership2.verification
      verification2.update(account_number: "123abc")
      verification.update(account_number: "123abc")
      expect(run).to contain_exactly(
        include(
          "factors" => [{"reason" => "account_number", "risk" => {"name" => "high", "value" => 1}}],
          "member_id" => member2.id,
        ),
      )
    end

    it "finds matches by exact name" do
      member2 = Suma::Fixtures.member.create(name: member_name)
      expect(run).to contain_exactly(
        include(
          "factors" => [{"reason" => "name", "risk" => {"name" => "high", "value" => 1}}],
          "member_id" => member2.id,
        ),
      )
    end

    it "finds matches with a fuzzy name match" do
      Suma::Fixtures.member.create(name: "George Galkis")
      member2 = Suma::Fixtures.member.create(name: "Robert Galanakis")
      expect(run).to contain_exactly(
        include(
          "factors" => [{"reason" => "name", "risk" => {"name" => "medium", "value" => 0.5}}],
          "member_id" => member2.id,
        ),
      )
    end

    it "finds matches by former phone number" do
      member2 = Suma::Fixtures.member.create(previous_phones: ["15551112222", phone, "15553339999"])
      expect(run).to contain_exactly(
        include(
          "factors" => [{"reason" => "contact", "risk" => {"name" => "high", "value" => 1}}],
          "member_id" => member2.id,
        ),
      )
    end

    it "finds matches by former email" do
      member2 = Suma::Fixtures.member.create(previous_emails: ["a2@b.c", email, "a4@b.c"])
      expect(run).to contain_exactly(
        include(
          "factors" => [{"reason" => "contact", "risk" => {"name" => "high", "value" => 1}}],
          "member_id" => member2.id,
        ),
      )
    end

    it "finds members with the same address" do
      member2 = Suma::Fixtures.member.create
      member2.legal_entity.update(address:)
      expect(run).to contain_exactly(
        include(
          "factors" => [{"reason" => "address", "risk" => {"name" => "high", "value" => 1}}],
          "member_id" => member2.id,
        ),
      )
    end

    it "finds members with a fuzzy address match" do
      member2 = Suma::Fixtures.member.create
      new_addr = address.values.dup
      new_addr[:address2] = new_addr[:address2].upcase
      new_addr[:address1] = "123 Main Str"
      member2.legal_entity.update(address: Suma::Address.lookup(new_addr))
      expect(run).to contain_exactly(
        include(
          "factors" => [{"reason" => "address", "risk" => {"name" => "medium", "value" => 0.5}}],
          "member_id" => member2.id,
        ),
      )
    end

    it "finds members with a different address2" do
      member2 = Suma::Fixtures.member.create
      new_addr = address.values.dup
      new_addr[:address2] = "APT 9"
      member2.legal_entity.update(address: Suma::Address.lookup(new_addr))
      expect(run).to contain_exactly(
        include(
          "factors" => [{"reason" => "address", "risk" => {"name" => "low", "value" => 0.1}}],
          "member_id" => member2.id,
        ),
      )
    end

    it "does not match on address if missing" do
      member2 = Suma::Fixtures.member.create
      member2.legal_entity.update(address: nil)
      member.legal_entity.update(address: nil)
      expect(finder.run.matches).to be_empty
    end

    it "ranks matched members by risk" do
      member3 = Suma::Fixtures.member.create(name: member_name + "x")
      member2 = Suma::Fixtures.member.create(name: member_name)
      expect(run).to match_array(
        [
          include("member_id" => member2.id),
          include("member_id" => member3.id),
        ],
      )
    end
  end

  describe "lookup_matches" do
    it "fetches and sets cached matches if needed" do
      member2 = Suma::Fixtures.member.create(name: member_name)
      expect(described_class.lookup_matches(verification)).to contain_exactly(
        have_attributes(member_name: member2.name),
      )
      expect(verification.cached_duplicates_key).to be_present
      expect(verification.cached_duplicates).to contain_exactly(
        include("member_name" => member_name,
                "factors" => [{"reason" => "name", "risk" => {"name" => "high", "value" => 1}}],),
      )
      expect(verification.find_duplicates).to contain_exactly(
        have_attributes(member_name: member_name, factors: contain_exactly(have_attributes(reason: "name"))),
      )
    end

    it "returns cached matches if possible" do
      verification.cached_duplicates = [{member_name: "Ralph", factors: []}].to_json
      verification.cached_duplicates_key = described_class::CACHE_KEY
      expect(described_class.lookup_matches(verification)).to contain_exactly(
        have_attributes(member_name: "Ralph"),
      )
    end
  end

  describe "duplicate_risk" do
    it "returns the risk of the first match (since matches are stored pre-sorted)" do
      matches = [
        described_class::SerializedMatch.new(
          factors: [
            described_class::Factor.new(reason: :name, risk: described_class::LOW),
            described_class::Factor.new(reason: :name, risk: described_class::HIGH),
          ],
        ),
        described_class::SerializedMatch.new(
          factors: [
            described_class::Factor.new(reason: :name, risk: described_class::MEDIUM),
          ],
        ),
      ]
      verification.cached_duplicates_key = described_class::CACHE_KEY
      verification.cached_duplicates = matches.as_json
      expect(verification.duplicate_risk.as_json).to eq(described_class::HIGH.as_json)
    end

    it "returns nil if no duplicates" do
      verification.cached_duplicates_key = described_class::CACHE_KEY
      verification.cached_duplicates = [].to_json
      expect(verification.duplicate_risk).to be_nil
    end
  end

  describe "caching" do
    it "clears the cache when account number is set" do
      verification.cached_duplicates_key = described_class::CACHE_KEY
      verification.update(account_number: "x")
      expect(verification).to have_attributes(cached_duplicates_key: "")
    end
  end
end
