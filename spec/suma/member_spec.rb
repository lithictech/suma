# frozen_string_literal: true

require "suma/behaviors"

RSpec.describe "Suma::Member", :db do
  let(:described_class) { Suma::Member }

  it "can be inspected" do
    expect { Suma::Member.new.inspect }.to_not raise_error
  end

  describe "associations" do
    it "has an ongoing_trip association" do
      c = Suma::Fixtures.member.with_cash_ledger.create
      Suma::Fixtures.ledger.member(c).category(:mobility).create # So we can end trip
      expect(c.ongoing_trip).to be_nil
      t = Suma::Fixtures.mobility_trip.ongoing.create(member: c)
      expect(c.refresh.ongoing_trip).to be === t
      t.end_trip(lat: 1, lng: 2)
      expect(c.refresh.ongoing_trip).to be_nil
    end

    it "has an orders association" do
      o = Suma::Fixtures.order.create
      member = o.checkout.cart.member

      expect(member.orders).to contain_exactly(be === o)
    end

    it "has payment instrument associations" do
      ba = Suma::Fixtures.bank_account.member.create
      expect(ba.member.bank_accounts).to have_same_ids_as(ba)
      card = Suma::Fixtures.card.member.create
      expect(card.member.cards).to have_same_ids_as(card)
    end
  end

  it "can guess names" do
    m = Suma::Fixtures.member.instance
    m.name = ""
    expect(m.guessed_first_last_name).to eq(["", ""])
    m.name = "  "
    expect(m.guessed_first_last_name).to eq(["", ""])
    m.name = "Marcus"
    expect(m.guessed_first_last_name).to eq(["Marcus", ""])
    m.name = "Marcus Galanakis "
    expect(m.guessed_first_last_name).to eq(["Marcus", "Galanakis"])
    m.name = "Marcus Reynir Galanakis"
    expect(m.guessed_first_last_name).to eq(["Marcus", "Reynir Galanakis"])
  end

  context "ensure_role" do
    let(:member) { Suma::Fixtures.member.create }
    let(:role) { Suma::Role.create(name: "member-test") }
    it "can set a role by a role object" do
      member.ensure_role(role)

      expect(member.roles).to contain_exactly(role)
    end

    it "can set a role by the role name" do
      member.ensure_role(role.name)
      expect(member.roles).to contain_exactly(role)
    end

    it "noops if the member already has the role" do
      member.ensure_role(role.name)
      member.ensure_role(role.name)
      member.ensure_role(role)
      member.ensure_role(role)
      expect(member.roles).to contain_exactly(role)
    end
  end

  describe "authenticate" do
    let(:password) { "testtest1" }

    it "returns true if the password matches" do
      u = Suma::Member.new
      u.password = password
      expect(u.authenticate?(password)).to be_truthy
    end

    it "returns false if the password does not match" do
      u = Suma::Member.new
      u.password = "testtest1"
      expect(u.authenticate?("testtest2")).to be_falsey
    end

    it "returns false if the new password is blank" do
      u = Suma::Member.new
      expect(u.authenticate?(nil)).to be_falsey
      expect(u.authenticate?("")).to be_falsey

      space = "          "
      u.password = space
      expect(u.authenticate?(space)).to be_truthy
    end

    it "cannot auth after being removed" do
      u = Suma::Fixtures.member.create
      u.soft_delete
      u.password = password
      expect(u.authenticate?(password)).to be_falsey
    end
  end

  describe "setting password" do
    let(:member) { Suma::Fixtures.member.instance }

    it "sets the digest to a bcrypt hash" do
      member.password = "abcdefg123"
      expect(member.password_digest.to_s).to have_length(described_class::PLACEHOLDER_PASSWORD_DIGEST.to_s.length)
    end

    it "uses the placeholder for a nil password" do
      member.password = nil
      expect(member.password_digest).to be === described_class::PLACEHOLDER_PASSWORD_DIGEST
    end

    it "fails if the password is not complex enough" do
      expect { member.password = "" }.to raise_error(described_class::InvalidPassword)
    end
  end

  describe "verification" do
    let(:c) { Suma::Fixtures.member.instance }

    def skip_verification?(c, list=nil)
      list ||= ["*autoverify@lithic.tech", "1555*"]
      return c.class.matches_allowlist?(c, list)
    end

    it "says if member is allowlisted based on phone or email" do
      c.phone = nil
      expect(skip_verification?(c.set(email: "rob@lithic.tech"))).to be_falsey
      expect(skip_verification?(c.set(email: "rob+autoverify@lithic.tech"))).to be_truthy
      c.email = nil
      expect(skip_verification?(c.set(phone: "14443332222"))).to be_falsey
      expect(skip_verification?(c.set(phone: "15553334444"))).to be_truthy

      expect(skip_verification?(c.set(phone: "15553334444"), [])).to be_falsey
    end
  end

  describe "onboarded?" do
    it "is false if address or name fields are missing" do
      c = Suma::Fixtures.member.create(name: "")
      expect(c).to_not be_onboarded

      c.name = "X"
      expect(c).to_not be_onboarded

      c.refresh
      addr = Suma::Fixtures.address.create
      c.legal_entity.address = addr
      expect(c).to_not be_onboarded

      c.refresh
      c.name = "X"
      c.legal_entity.address = addr
      expect(c).to be_onboarded
    end
  end

  it_behaves_like "has a timestamp predicate", "onboarding_verified_at", "onboarding_verified" do
    let(:instance) { Suma::Fixtures.member.instance }
  end

  describe "phone number" do
    it "formats the phone when setting us_phone" do
      c = Suma::Fixtures.member.instance
      c.us_phone = "555-123-4567"
      expect(c.phone).to eq("15551234567")
      expect(c.us_phone).to eq("(555) 123-4567")
    end
  end

  describe "legal entity" do
    let(:c) { Suma::Fixtures.member.with_legal_entity.instance }

    it "gets its name copied on member update if it is blank" do
      c.legal_entity.update(name: "")
      c.update(name: "Jim Davis")
      expect(c.legal_entity.refresh).to have_attributes(name: "Jim Davis")
      expect(c.legal_entity.member).to be === c
    end

    it "gets its name copied on member update if it matches the previous value" do
      c.update(name: "Jim Davis")
      c.legal_entity.update(name: "Jim Davis")
      c.update(name: "James Davis")
      expect(c.legal_entity.refresh).to have_attributes(name: "James Davis")
    end

    it "does not change if distinct" do
      c.update(name: "Jim Davis")
      c.legal_entity.update(name: "Garfield")
      c.update(name: "James Davis")
      expect(c.legal_entity.refresh).to have_attributes(name: "Garfield")
    end
  end

  describe "read_only_mode" do
    it "is true if the member has no payment account" do
      c = Suma::Fixtures.member.onboarding_verified.create
      expect(c).to be_read_only_mode
      expect(c).to have_attributes(read_only_reason: "read_only_technical_error")
    end

    it "is true if the member has not been verified" do
      c = Suma::Fixtures.member.with_cash_ledger(amount: money("$5")).create
      expect(c).to be_read_only_mode
      expect(c).to have_attributes(read_only_reason: "read_only_unverified")
    end

    it "is false if the member is verified and has a payment account" do
      c = Suma::Fixtures.member.onboarding_verified.with_cash_ledger(amount: money("$5")).create
      expect(c).to have_attributes(read_only_reason: nil, read_only_mode?: false)
    end

    it "raises for read_only_mode! if in read only" do
      c = Suma::Fixtures.member.onboarding_verified.with_cash_ledger(amount: money("$5")).create
      expect { c.read_only_mode! }.to_not raise_error
      c.onboarding_verified = false
      expect { c.read_only_mode! }.to raise_error(described_class::ReadOnlyMode)
    end
  end

  describe "usable_payment_instruments", reset_configuration: Suma::Payment do
    let(:member) { Suma::Fixtures.member.create }
    let(:bank_fac) { Suma::Fixtures.bank_account.member(member) }
    let(:card_fac) { Suma::Fixtures.card.member(member) }

    it "returns undeleted bank accounts and cards" do
      deleted_ba = bank_fac.create
      deleted_ba.soft_delete
      deleted_card = card_fac.create
      deleted_card.soft_delete

      ba2 = bank_fac.create
      c1 = card_fac.create
      ba1 = bank_fac.create
      c2 = card_fac.create

      expect(member.usable_payment_instruments).to have_same_ids_as(ba1, ba2, c2, c1).ordered
    end

    it "excludes unsupported payment methods" do
      c1 = card_fac.create
      ba1 = bank_fac.create

      expect(member.usable_payment_instruments).to have_same_ids_as(ba1, c1)
      Suma::Payment.supported_methods = ["card"]
      expect(member.usable_payment_instruments).to have_same_ids_as(c1)
    end
  end

  describe "soft deleting" do
    it "sets email and password" do
      c = Suma::Fixtures.member(email: "a@b.c", password: "password").create
      expect do
        c.soft_delete
      end.to(change { c.password_digest })
      expect(c.email).to match(/^[0-9]+\.[0-9]+\+a@b\.c$/)
    end

    it "sets phone to an invalid, unused phone number" do
      c = Suma::Fixtures.member(phone: "15551234567").create
      c.soft_delete
      expect(c.phone).to_not eq("15551234567")
      expect(c.phone).to have_length(15)
      expect(c.note).to include("15551234567")
    end

    it "can retrieve the display email" do
      c = Suma::Fixtures.member(email: "x@y.com").create
      expect(c.display_email).to eq("x@y.com")
      c.soft_delete
      expect(c.display_email).to eq("x@y.com")
    end

    it "can handle a nil email" do
      c = Suma::Fixtures.member.create.update(email: nil)
      expect(c).to have_attributes(email: nil, display_email: nil)
      c.soft_delete
      expect(c).to have_attributes(email: nil, display_email: nil)
    end
  end

  describe "requires_terms_agreement?" do
    it "is true if no terms are accepted" do
      expect(Suma::Fixtures.member.instance).to be_requires_terms_agreement
    end

    it "is true if the accepted terms date is before the latest one" do
      expect(Suma::Fixtures.member(terms_agreed: Date.new(1900, 1, 1)).instance).to be_requires_terms_agreement
    end

    it "is false if the accepted terms date is on or after the latest one" do
      expect(Suma::Fixtures.member(terms_agreed: Date.new(2300, 1, 1)).instance).to_not be_requires_terms_agreement
      date = described_class::LATEST_TERMS_PUBLISH_DATE
      expect(Suma::Fixtures.member(terms_agreed: date).instance).to_not be_requires_terms_agreement
    end
  end

  describe "masking" do
    it "masks name/phone/email" do
      mem = described_class.new
      expect(mem).to have_attributes(
        masked_name: "***",
        masked_email: "***",
        masked_phone: "***",
      )
      mem.name = "a"
      mem.email = "a"
      mem.phone = "a"
      expect(mem).to have_attributes(
        masked_name: "***",
        masked_email: "***",
        masked_phone: "***",
      )

      mem.name = "Pedro Pascal"
      mem.email = "pedro@pascal.org"
      mem.phone = "15552223333"
      expect(mem).to have_attributes(
        masked_name: "Pe***al",
        masked_email: "ped***al.org",
        masked_phone: "5***33",
      )

      mem.name = "Pedro"
      mem.email = "ped@pas.org"
      expect(mem).to have_attributes(
        masked_name: "***",
        masked_email: "***",
      )
    end
  end

  describe "organizations" do
    describe "ensure_membership_in_organization" do
      let(:m) { Suma::Fixtures.member.create }
      let(:o) { Suma::Fixtures.organization.create }

      around(:each) do |example|
        # Needed for auditing
        Suma.set_request_user_and_admin(m, nil) do
          example.run
        end
      end

      it "reuses an existing verified membership" do
        membership = m.add_organization_membership(verified_organization: o)
        expect(m.ensure_membership_in_organization(o.name)).to be === membership
      end

      it "reuses an existing unverified membership" do
        membership = m.add_organization_membership(unverified_organization_name: o.name)
        expect(m.ensure_membership_in_organization(o.name)).to be === membership
      end

      it "does not use a former membership" do
        membership = m.add_organization_membership(former_organization: o, formerly_in_organization_at: Time.now)
        m2 = m.ensure_membership_in_organization(o.name)
        expect(m2).to_not be === membership
        expect(m2.id).to be > membership.id
      end

      it "creates a new unverified membership" do
        membership = m.ensure_membership_in_organization(o.name)
        expect(membership).to have_attributes(member: be === m, verified?: false)
      end

      it "strips whitespace" do
        membership = m.ensure_membership_in_organization(" abc ")
        expect(membership).to have_attributes(unverified_organization_name: "abc")
      end
    end
  end

  describe "enrollments" do
    let(:member) { Suma::Fixtures.member.create }
    let(:organization) { Suma::Fixtures.organization.create }
    let(:role) { Suma::Role.create(name: "role access") }

    it "can fetch direct enrollments" do
      e = Suma::Fixtures.program_enrollment(member:).create
      expect(member.direct_program_enrollments_dataset.all).to have_same_ids_as(e)
    end

    it "can fetch organization enrollments" do
      Suma::Fixtures.organization_membership(member:).verified(organization).create
      e = Suma::Fixtures.program_enrollment(organization:).create
      expect(member.program_enrollments_via_organizations_dataset.all).to have_same_ids_as(e)
    end

    it "can fetch role enrollments" do
      role = Suma::Role.create(name: "test")
      member.add_role(role)
      e = Suma::Fixtures.program_enrollment(role:).create
      expect(member.program_enrollments_via_roles_dataset.all).to have_same_ids_as(e)
    end

    it "can fetch organization role enrollments" do
      role = Suma::Role.create(name: "test")
      organization.add_role(role)
      Suma::Fixtures.organization_membership(member:).verified(organization).create
      e = Suma::Fixtures.program_enrollment(role:).create
      expect(member.program_enrollments_via_organization_roles_dataset.all).to have_same_ids_as(e)
    end

    it "can fetch direct, role-based, organizational, and organizational role based enrollments" do
      Suma::Fixtures.organization_membership(member:).verified(organization).create
      member.add_role(role)
      org_role = Suma::Role.create(name: "org_test_role")
      org_with_role = Suma::Fixtures.organization.create
      org_with_role.add_role(org_role)
      Suma::Fixtures.organization_membership(member:).verified(org_with_role).create

      active_via_member = Suma::Fixtures.program_enrollment(member:).create
      active_via_org = Suma::Fixtures.program_enrollment(organization:).create
      active_via_role = Suma::Fixtures.program_enrollment(role:).create
      active_via_org_role = Suma::Fixtures.program_enrollment(role: org_role).create
      expect(member.combined_program_enrollments_dataset.all).to have_same_ids_as(
        active_via_member, active_via_org, active_via_role, active_via_org_role,
      )

      eagered_member = Suma::Member.all.first
      expect(eagered_member.combined_program_enrollments).to have_same_ids_as(
        active_via_member, active_via_org, active_via_role, active_via_org_role,
      )
    end

    describe "with redundant enrollment directly, and through org and role" do
      it "returns the direct enrollment" do
        r = Suma::Role.create(name: "role access")
        member.add_role(r)
        o = Suma::Fixtures.organization.with_membership_of(member).create
        program = Suma::Fixtures.program.create
        # Create the enrollments in a random order to ensure we don't depend on random/chance ordering
        [{member:}, {organization: o}, {role: r}].shuffle.each do |p|
          Suma::Fixtures.program_enrollment.create(program:, **p)
        end
        member_enrollment = member.direct_program_enrollments.first
        # Prefer the member/direct enrollment over the org/indirect enrollment
        expect(member.combined_program_enrollments_dataset.all).to have_same_ids_as(member_enrollment)
        expect(Suma::Member.all.last.combined_program_enrollments).to have_same_ids_as(member_enrollment)
      end
    end

    describe "with redudant enrollment through org and role" do
      it "returns the org enrollment" do
        r = Suma::Role.create(name: "role access")
        member.add_role(r)
        o = Suma::Fixtures.organization.with_membership_of(member).create
        program = Suma::Fixtures.program.create
        # Create the enrollments in a random order to ensure we don't depend on random/chance ordering
        [{organization: o}, {role: r}].shuffle.each do |p|
          Suma::Fixtures.program_enrollment.create(program:, **p)
        end
        org_enrollment = member.program_enrollments_via_organizations.first
        expect(member.combined_program_enrollments_dataset.all).to have_same_ids_as(org_enrollment)
        expect(Suma::Member.all.last.combined_program_enrollments).to have_same_ids_as(org_enrollment)
      end
    end
  end

  describe "previous phone/email" do
    it "appends to the previous list on email and phone changes" do
      m = Suma::Fixtures.member.create(email: "a@b.c", phone: "12223334444")
      expect(m).to have_attributes(previous_emails: [], previous_phones: [])
      m.update(email: "a2@b.c")
      expect(m).to have_attributes(previous_emails: ["a@b.c"], previous_phones: [])
      m.update(phone: "13334445555")
      expect(m).to have_attributes(previous_emails: ["a@b.c"], previous_phones: ["12223334444"])
      m.update(name: "Hello Word")
      expect(m).to have_attributes(previous_emails: ["a@b.c"], previous_phones: ["12223334444"])
      m.update(email: "x@y.z", phone: "14445556666")
      expect(m).to have_attributes(
        previous_emails: ["a2@b.c", "a@b.c"], previous_phones: ["13334445555", "12223334444"],
      )
    end
  end

  describe "hybrid search" do
    it "handles a bad or missing phone number" do
      m = Suma::Fixtures.member.email.instance(phone: "555")
      expect(m.hybrid_search_text).to match(/Phone number: 555/)

      m = Suma::Fixtures.member.email.instance(phone: nil)
      expect(m.hybrid_search_text).to match(/Phone number: /)
    end

    it "exercises coverage" do
      member = Suma::Fixtures.member.create
      Suma::Fixtures.anon_proxy_member_contact.create(member:)
      expect(member.hybrid_search_text).to match(/Anonymous Contacts: \["u/)
    end
  end
end
