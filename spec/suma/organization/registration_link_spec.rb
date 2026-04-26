# frozen_string_literal: true

RSpec.describe "Suma::Organization::RegistrationLink", :db do
  let(:described_class) { Suma::Organization::RegistrationLink }

  it "can fixture itself" do
    expect(Suma::Fixtures.registration_link.create).to be_a(described_class)
  end

  describe "associations" do
    it "can be associated with a membership" do
      link = Suma::Fixtures.registration_link.create
      mem = Suma::Fixtures.organization_membership.verified.create(registration_link: link)
      expect(link.memberships).to contain_exactly(be === mem)
    end
  end

  describe "durable_url" do
    it "returns a url with the opaque id" do
      link = Suma::Fixtures.registration_link.create(opaque_id: "xyz")
      expect(link.durable_url).to eq("http://localhost:22001/api/v1/registration_links/xyz")
    end

    it "can generate a qr code" do
      link = Suma::Fixtures.registration_link.create(opaque_id: "xyz")
      expect(link.durable_url_qr_code_data_url(size: 4)).to eq(
        "data:image/png;base64," \
        "iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAAAAACMmsGiAAAAEElEQVR4nGP6DwRMDECAIABGMgQFsmeHFwAAAABJRU5ErkJggg==",
      )
    end
  end

  describe "make_code_capture_url" do
    it "returns a url with a unique code each call" do
      link = Suma::Fixtures.registration_link.create
      expect(Suma::Secureid).to receive(:rand_enc).and_return("xyz")
      url = link.make_code_capture_url
      expect(url).to eq("http://localhost:22001/api/v1/registration_links/capture?suma_regcode=xyz")
    end
  end

  describe "partner_signup_url" do
    it "returns a url" do
      expect(described_class.partner_signup_url).to eq("http://localhost:22004/partner-signup")
    end
  end

  describe "lookup_from_code" do
    it "can be looked up form a one time code" do
      link = Suma::Fixtures.registration_link.create
      code = link.make_one_time_code
      link2 = described_class.lookup_from_code(code, at: Time.now)
      expect(link2).to be === link
    end

    it "is nil if there is no stored code" do
      link = described_class.lookup_from_code("xyz", at: Time.now)
      expect(link).to be_nil
    end

    it "is nil if the link does not exist" do
      link = Suma::Fixtures.registration_link.create
      code = link.make_one_time_code
      link.destroy
      link2 = described_class.lookup_from_code(code, at: Time.now)
      expect(link2).to be_nil
    end

    describe "when an ical vevent is set" do
      it "returns nil if the given time does does not match the rrule" do
        link = Suma::Fixtures.registration_link.create(
          ical_dtstart: Time.parse("20250418T120000Z"),
          ical_dtend: Time.parse("20250418T130000Z"),
          ical_rrule: "COUNT=5;INTERVAL=1;FREQ=DAILY",
        )
        code = link.make_one_time_code
        Timecop.freeze("20250418T120001Z") do
          expect(described_class.lookup_from_code(code, at: Time.now)).to be === link
        end
        Timecop.freeze("20260418T120001Z") do # next year, already past occurrences
          expect(described_class.lookup_from_code(code, at: Time.now)).to be_nil
        end
        Timecop.freeze("20250418T140001Z") do # outside the time window (2pm)
          expect(described_class.lookup_from_code(code, at: Time.now)).to be_nil
        end
      end
    end
  end

  describe "within_schedule" do
    it "handles times" do
      link = Suma::Fixtures.registration_link(
        ical_dtstart: Time.parse("20250418T120000Z"),
        ical_dtend: Time.parse("20250418T130000Z"),
        ical_rrule: "COUNT=5;INTERVAL=1;FREQ=DAILY",
      ).instance
      expect(link.within_schedule?(Time.parse("20250418T120000Z"))).to be(true)
      expect(link.within_schedule?(Time.parse("20250419T120001Z"))).to be(true) # next day
      expect(link.within_schedule?(Time.parse("20260418T120001Z"))).to be(false) # next year, is past COUNT
      expect(link.within_schedule?(Time.parse("20250418T140001Z"))).to be(false) # after DTEND
    end

    it "treats missing start or end as closed" do
      link = Suma::Fixtures.registration_link.instance
      link.ical_dtstart = Time.parse("20250418T120000Z")
      expect(link.within_schedule?(Time.parse("20250418T120001Z"))).to be(false)
      link.ical_dtstart = nil
      link.ical_dtend = Time.parse("20250418T130000Z")
    end

    it "treats invalid RRULE as closed" do
      link = Suma::Fixtures.registration_link(
        ical_dtstart: Time.parse("20250418T120000Z"),
        ical_dtend: Time.parse("20250418T130000Z"),
        ical_rrule: "X",
      ).instance
      expect(link.within_schedule?(Time.parse("20250418T120000Z"))).to be(false)
    end

    it "works without an rrule" do
      link = Suma::Fixtures.registration_link(
        ical_dtstart: Time.parse("20250418T120000Z"),
        ical_dtend: Time.parse("20250418T130000Z"),
      ).instance
      expect(link.within_schedule?(Time.parse("20250418T120001Z"))).to be(true)
      expect(link.within_schedule?(Time.parse("20250419T120001Z"))).to be(false) # next day
    end
  end

  describe "ical fields" do
    it "allows mixing and matching of fields to be set and not set" do
      link = Suma::Fixtures.registration_link.create
      expect { link.update(ical_dtstart: Time.now, ical_dtend: nil, ical_rrule: "") }.to_not raise_error
      expect { link.update(ical_dtstart: nil, ical_dtend: Time.now, ical_rrule: "") }.to_not raise_error
      expect { link.update(ical_dtstart: nil, ical_dtend: nil, ical_rrule: "COUNT=5") }.to_not raise_error
      expect { link.update(ical_dtstart: Time.now, ical_dtend: Time.now, ical_rrule: "COUNT=5") }.to_not raise_error
    end

    it "ignores an invalid rrule" do
      link = Suma::Fixtures.registration_link.create
      link.update(ical_rrule: "XY")
      expect(link.within_schedule?(Time.parse("20250419T120001Z"))).to be(false)
    end

    it "can assemble an entire event" do
      link = Suma::Fixtures.registration_link.instance
      expect(link.ical_vevent(tags: true)).to eq(<<~VEVENT.strip)
        BEGIN:VEVENT
        END:VEVENT
      VEVENT
      link.set(
        ical_dtstart: Time.parse("20250418T120000Z"),
        ical_dtend: Time.parse("20250418T130000Z"),
        ical_rrule: "COUNT=5;INTERVAL=1;FREQ=DAILY",
      )
      expect(link.ical_vevent(tags: false)).to eq(<<~VEVENT.strip)
        DTSTART:20250418T120000Z
        DTEND:20250418T130000Z
        RRULE:COUNT=5;INTERVAL=1;FREQ=DAILY
      VEVENT
    end
  end

  describe "from_params" do
    it "returns the link from the code" do
      link = Suma::Fixtures.registration_link.create
      code = link.make_one_time_code
      andcode = described_class.from_params({"suma_regcode" => code}, at: Time.now)
      expect(andcode).to have_attributes(code:, link: be === link)
    end

    it "is nil if there is no param" do
      expect(described_class.from_params({}, at: Time.now)).to be_nil
    end

    it "is nil if the code does not map to a link" do
      andcode = described_class.from_params({"suma_regcode" => "x"}, at: Time.now)
      expect(andcode).to be_nil
    end
  end

  describe "ensure_verified_membership" do
    let(:org) { Suma::Fixtures.organization.create }
    let(:reglink) { Suma::Fixtures.registration_link(organization: org).create }
    let(:member) { Suma::Fixtures.member.create }

    describe "when there is an existing unverified membership to the org" do
      it "verifies the membership" do
        other_membership = Suma::Fixtures.organization_membership.unverified.create(member:)
        membership = Suma::Fixtures.organization_membership.unverified(org.name).create(member:)
        expect(reglink.ensure_verified_membership(member, code: "x")).to be === membership
        expect(membership.refresh).to have_attributes(
          verified_organization: be === org,
          registration_link: be === reglink,
        )
      end

      it "updates the verification" do
        membership = Suma::Fixtures.organization_membership.unverified(org.name).create(member:)
        v = membership.verification
        reglink.ensure_verified_membership(member, code: "x")
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
      expect(reglink.ensure_verified_membership(member, code: "x")).to be === membership
      expect(membership.refresh).to have_attributes(registration_link: nil)
    end

    it "creates a verified membership if there is no membership" do
      membership = reglink.ensure_verified_membership(member, code: "x")
      expect(membership).to have_attributes(
        member: be === member,
        verified_organization: be === org,
        registration_link: be === reglink,
      )
    end

    it "creates a verified membership if there is a former membership" do
      old = Suma::Fixtures.organization_membership.former(org).create(member:)
      membership = reglink.ensure_verified_membership(member, code: "x")
      expect(old).to_not be === membership
      expect(old.refresh).to have_attributes(former_organization: be === org, member: be === member)
      expect(membership).to have_attributes(
        member: be === member,
        verified_organization: be === org,
        registration_link: be === reglink,
      )
    end

    it "deletes the one-time code" do
      code = reglink.make_one_time_code
      reglink.ensure_verified_membership(member, code:)
      expect(described_class.lookup_from_code(code, at: Time.now)).to be_nil
    end
  end
end
