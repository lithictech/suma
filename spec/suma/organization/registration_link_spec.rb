# frozen_string_literal: true

RSpec.describe "Suma::Organization::RegistrationLink", :db do
  let(:described_class) { Suma::Organization::RegistrationLink }

  it "can fixture itself" do
    expect(Suma::Fixtures.organization_registration_link.create).to be_a(described_class)
  end

  describe "associations" do
    it "can be associated with a membership" do
      link = Suma::Fixtures.organization_registration_link.create
      mem = Suma::Fixtures.organization_membership.verified.create(registration_link: link)
      expect(link.memberships).to contain_exactly(be === mem)
    end
  end

  describe "durable_url" do
    it "returns a url with the opaque id" do
      link = Suma::Fixtures.organization_registration_link.create(opaque_id: "xyz")
      expect(link.durable_url).to eq("http://localhost:22001/api/registration_links/xyz")
    end
  end

  describe "make_one_time_url" do
    it "returns a url with a unique code each call" do
      link = Suma::Fixtures.organization_registration_link.create
      expect(Suma::Secureid).to receive(:rand_enc).and_return("xyz")
      url = link.make_one_time_url
      expect(url).to eq("http://localhost:22004/partner/#{link.organization.id}?suma_regcode=xyz")
    end
  end

  describe "lookup_from_code" do
    it "can be looked up form a one time code" do
      link = Suma::Fixtures.organization_registration_link.create
      code = link.set_one_time_code
      link2 = described_class.lookup_from_code(code)
      expect(link2).to be === link
    end

    it "is nil if there is no stored code" do
      link = described_class.lookup_from_code("xyz")
      expect(link).to be.nil?
    end

    it "is nil if the link does not exist" do
      link = Suma::Fixtures.organization_registration_link.create
      code = link.set_one_time_code
      link.destroy
      link2 = described_class.lookup_from_code(code)
      expect(link2).to be_nil
    end
  end

  describe "from_params" do
    it "returns the link from the code" do
      link = Suma::Fixtures.organization_registration_link.create
      code = link.set_one_time_code
      link2 = described_class.from_params({"suma_regcode" => code})
      expect(link2).to be === link
    end

    it "is nil if there is no param" do
      expect(described_class.from_params({})).to be_nil
    end
  end

  describe "ensure_verified_membership" do
    let(:org) { Suma::Fixtures.organization.create }
    let(:reglink) { Suma::Fixtures.organization_registration_link(organization: org).create }
    let(:member) { Suma::Fixtures.member.create }

    describe "when there is an existing unverified membership to the org" do
      it "verifies the membership" do
        other_membership = Suma::Fixtures.organization_membership.unverified.create(member:)
        membership = Suma::Fixtures.organization_membership.unverified(org.name).create(member:)
        expect(reglink.ensure_verified_membership(member)).to be === membership
        expect(membership.refresh).to have_attributes(
          verified_organization: be === org,
          registration_link: be === reglink,
        )
      end

      it "updates the verification" do
        membership = Suma::Fixtures.organization_membership.unverified(org.name).create(member:)
        v = membership.verification
        reglink.ensure_verified_membership(member)
        expect(membership.refresh).to have_attributes(
          verified_organization: be === org,
          registration_link: be === reglink,
        )
        expect(v.refresh).to have_attributes(status: "verified")
      end
    end

    it "uses an existing verified membership" do
      other_membership = Suma::Fixtures.organization_membership.verified.create(member:)
      membership = Suma::Fixtures.organization_membership.verified(org).create(member:)
      expect(reglink.ensure_verified_membership(member)).to be === membership
      expect(membership.refresh).to have_attributes(registration_link: nil)
    end

    it "creates a verified membership if there is no membership" do
      membership = reglink.ensure_verified_membership(member)
      expect(membership).to have_attributes(
        member: be === member,
        verified_organization: be === org,
        registration_link: be === reglink,
      )
    end

    it "creates a verified membership if there is a former membership" do
      old = Suma::Fixtures.organization_membership.former(org).create(member:)
      membership = reglink.ensure_verified_membership(member)
      expect(old).to_not be === membership
      expect(old.refresh).to have_attributes(former_organization: be === org, member: be === member)
      expect(membership).to have_attributes(
        member: be === member,
        verified_organization: be === org,
        registration_link: be === reglink,
      )
    end
  end
end
