# frozen_string_literal: true

RSpec.describe "Suma::AnonProxy::VendorAccount", :db do
  let(:described_class) { Suma::AnonProxy::VendorAccount }

  describe "::for" do
    it "returns existing enabled vendor accounts and creates new for configured vendors" do
      member = Suma::Fixtures.member.onboarding_verified.create
      cfg_fac = Suma::Fixtures.anon_proxy_vendor_configuration
      vc_with_acct = cfg_fac.create
      vc_without_acct = cfg_fac.create
      vc_disabled_with_acct = cfg_fac.disabled.create
      vc_disabled_without_acct = cfg_fac.disabled.create
      good_vacct = Suma::Fixtures.anon_proxy_vendor_account(member:, configuration: vc_with_acct).create
      disabled_vacct = Suma::Fixtures.anon_proxy_vendor_account(member:, configuration: vc_disabled_with_acct).create

      got = described_class.for(member)
      expect(got).to contain_exactly(
        be === good_vacct,
        have_attributes(configuration: be === vc_without_acct),
      )
    end

    it "is empty if the member is unverified" do
      member = Suma::Fixtures.member.create
      Suma::Fixtures.anon_proxy_vendor_configuration.create
      expect(described_class.for(member)).to be_empty

      member.onboarding_verified = true
      expect(described_class.for(member)).to have_length(1)
    end

    it "applies eligibility constraints" do
      member = Suma::Fixtures.member.onboarding_verified.create
      cfg = Suma::Fixtures.anon_proxy_vendor_configuration.create
      constraint = Suma::Fixtures.eligibility_constraint.create

      # No constraints means everyone can access
      expect(described_class.for(member.refresh)).to contain_exactly(have_attributes(configuration: be === cfg))

      # Constrained restricts access
      cfg.add_eligibility_constraint(constraint)
      expect(described_class.for(member.refresh)).to be_empty

      # Member can now access
      member.add_verified_eligibility_constraint(constraint)
      expect(described_class.for(member.refresh)).to contain_exactly(have_attributes(configuration: be === cfg))
    end
  end

  describe "email and sms" do
    it "finds the member contact with an email or sms" do
      vc = Suma::Fixtures.anon_proxy_vendor_configuration(uses_sms: false, uses_email: true).create
      va = Suma::Fixtures.anon_proxy_vendor_account(configuration: vc).create
      expect(va).to have_attributes(
        sms: nil,
        sms_required?: false,
        email: nil,
        email_required?: true,
      )
      vc.set(uses_sms: true, uses_email: false)
      expect(va).to have_attributes(
        sms: nil,
        sms_required?: true,
        email: nil,
        email_required?: false,
      )
      mc = Suma::Fixtures.anon_proxy_member_contact(email: "a@b.c", member: va.member).create
      va.contact = mc
      expect(va).to have_attributes(
        sms: nil,
        sms_required?: true,
        email: nil,
        email_required?: false,
      )
      mc.set(email: nil, phone: "12223334444")
      expect(va).to have_attributes(
        sms: "12223334444",
        sms_required?: false,
        email: nil,
        email_required?: false,
      )
    end
  end

  describe "#provision_contact" do
    let!(:va) { Suma::Fixtures.anon_proxy_vendor_account(configuration:).create }

    describe "using email" do
      let(:configuration) { Suma::Fixtures.anon_proxy_vendor_configuration.email.create }

      it "provisions a new email contact" do
        c = va.provision_contact
        expect(c).to be_a(Suma::AnonProxy::MemberContact)
        expect(c).to have_attributes(
          member: be === va.member,
          email: "u#{va.member.id}@example.com",
          phone: nil,
          relay_key: "fake-relay",
        )
      end

      it "noops for an existing member contact" do
        mc = Suma::Fixtures.anon_proxy_member_contact.email.create(member: va.member)
        c = va.provision_contact
        expect(c).to be === mc
      end
    end
  end

  describe "recent_message_text_bodies" do
    let(:va) { Suma::Fixtures.anon_proxy_vendor_account.create }

    it "returns text/plain bodies of messages sent within the last 5 minutes" do
      old = Suma::Fixtures.message_delivery.with_body(content: "old", mediatype: "text/plain").create
      new = Suma::Fixtures.message_delivery.with_body(content: "new", mediatype: "text/plain").create
      nontext = Suma::Fixtures.message_delivery.with_body(content: "nontext").create

      vam_fac = Suma::Fixtures.anon_proxy_vendor_account_message(vendor_account: va)
      old_vam = vam_fac.create(outbound_delivery: old)
      old_vam.this.update(created_at: 10.minutes.ago)
      new_vam = vam_fac.create(outbound_delivery: new)
      nontext_vam = vam_fac.create(outbound_delivery: nontext)

      expect(va.recent_message_text_bodies).to contain_exactly("new")
    end
  end

  describe "replace_access_code" do
    let(:va) { Suma::Fixtures.anon_proxy_vendor_account.create }

    it "sets vendor account latest_access fields" do
      va.replace_access_code("abc", "https://lime.app/magic_link_token=abc")
      expect(va).to have_attributes(
        latest_access_code: "abc",
        latest_access_code_magic_link: "https://lime.app/magic_link_token=abc",
      )
    end
  end

  describe "latest_access_code_is_recent?" do
    let(:va) { Suma::Fixtures.anon_proxy_vendor_account.create }

    it "returns true if latest_access_code is recent" do
      expect(va.latest_access_code_is_recent?).to equal(false)
      va.replace_access_code("abc", "https://lime.app/magic_link_token=abc")
      expect(va.latest_access_code_is_recent?).to equal(true)
    end
  end

  describe "auth_request" do
    let(:va) do
      Suma::Fixtures.anon_proxy_vendor_account.with_configuration(
        auth_url: "https://x.y",
        auth_http_method: "POST",
        auth_headers: {"X-Y" => "b"},
      ).create
    end

    it "returns the auth fields for the configuration" do
      expect(va.auth_request).to include(
        http_method: "POST",
        url: "https://x.y",
        headers: {"X-Y" => "b"},
        body: '{"email":"","phone":""}',
      )
    end

    it "can render phone and email" do
      va.contact = Suma::Fixtures.anon_proxy_member_contact.create
      va.contact.email = "x@y.z"
      va.contact.phone = "12223334444"
      expect(va.auth_request).to include(
        body: '{"email":"x@y.z","phone":"12223334444"}',
      )
    end
  end
end
