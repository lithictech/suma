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

  it "finds members with duplicate account numbers (on a verified membership)" do
    member2 = Suma::Fixtures.member.create
    membership2 = Suma::Fixtures.organization_membership.verified(org).create(member: member2)
    verification2 = Suma::Fixtures.organization_membership_verification.create(membership: membership2)
    verification2.update(account_number: "123abc")
    verification.update(account_number: "123abc")
    expect(finder.run.matches).to contain_exactly(
      have_attributes(verification: be === verification2, chance: :high, reason: :account_number),
    )
  end

  it "finds members with duplicate account numbers (on an unverified membership)" do
    member2 = Suma::Fixtures.member.create
    membership2 = Suma::Fixtures.organization_membership.unverified(org.name).create(member: member2)
    verification2 = membership2.verification
    verification2.update(account_number: "123abc")
    verification.update(account_number: "123abc")
    expect(finder.run.matches).to contain_exactly(
      have_attributes(verification: be === verification2, chance: :high, reason: :account_number),
    )
  end

  it "finds matches by exact name" do
    member2 = Suma::Fixtures.member.create(name: member_name)
    expect(finder.run.matches).to contain_exactly(
      have_attributes(member: be === member2, chance: :high, reason: :name),
    )
  end

  it "finds matches with a fuzzy name match" do
    Suma::Fixtures.member.create(name: "George Galkis")
    member2 = Suma::Fixtures.member.create(name: "Robert Galankis")
    expect(finder.run.matches).to contain_exactly(
      have_attributes(member: be === member2, chance: :medium, reason: :name),
    )
  end

  it "finds matches by former phone number" do
    member2 = Suma::Fixtures.member.create(previous_phones: ["15551112222", phone, "15553339999"])
    expect(finder.run.matches).to contain_exactly(
      have_attributes(member: be === member2, chance: :high, reason: :phone),
    )
  end

  it "finds matches by former email" do
    member2 = Suma::Fixtures.member.create(previous_emails: ["a2@b.c", email, "a4@b.c"])
    expect(finder.run.matches).to contain_exactly(
      have_attributes(member: be === member2, chance: :high, reason: :email),
    )
  end

  it "finds members with the same address" do
    member2 = Suma::Fixtures.member.create
    member2.legal_entity.update(address:)
    expect(finder.run.matches).to contain_exactly(
      have_attributes(member: be === member2, chance: :high, reason: :address),
    )
  end

  it "finds members with a fuzzy address match" do
    member2 = Suma::Fixtures.member.create
    new_addr = address.values.dup
    new_addr[:address2] = new_addr[:address2].upcase
    new_addr[:address1] = "123 Main Street"
    member2.legal_entity.update(address: Suma::Address.lookup(new_addr))
    expect(finder.run.matches).to contain_exactly(
      have_attributes(member: be === member2, chance: :medium, reason: :address),
    )
  end

  it "finds members with a different address2" do
    member2 = Suma::Fixtures.member.create
    new_addr = address.values.dup
    new_addr[:address2] = "Other Apt"
    new_addr[:address1] = "123 Main Street"
    member2.legal_entity.update(address: Suma::Address.lookup(new_addr))
    expect(finder.run.matches).to contain_exactly(
      have_attributes(member: be === member2, chance: :low, reason: :address),
    )
  end
end
