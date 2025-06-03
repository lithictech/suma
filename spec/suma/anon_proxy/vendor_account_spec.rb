# frozen_string_literal: true

RSpec.describe "Suma::AnonProxy::VendorAccount", :db do
  let(:described_class) { Suma::AnonProxy::VendorAccount }

  describe "::for" do
    let(:as_of) { Time.now }

    it "returns existing enabled vendor accounts and creates new for configured vendors" do
      member = Suma::Fixtures.member.onboarding_verified.create
      cfg_fac = Suma::Fixtures.anon_proxy_vendor_configuration
      vc_with_acct = cfg_fac.create
      vc_without_acct = cfg_fac.create
      vc_disabled_with_acct = cfg_fac.disabled.create
      vc_disabled_without_acct = cfg_fac.disabled.create
      good_vacct = Suma::Fixtures.anon_proxy_vendor_account(member:, configuration: vc_with_acct).create
      disabled_vacct = Suma::Fixtures.anon_proxy_vendor_account(member:, configuration: vc_disabled_with_acct).create

      got = described_class.for(member, as_of:)
      expect(got).to contain_exactly(
        be === good_vacct,
        have_attributes(configuration: be === vc_without_acct),
      )
    end

    it "is empty if the member is unverified" do
      member = Suma::Fixtures.member.create
      Suma::Fixtures.anon_proxy_vendor_configuration.create
      expect(described_class.for(member, as_of:)).to be_empty

      member.onboarding_verified = true
      expect(described_class.for(member, as_of:)).to have_length(1)
    end

    it "applies program eligibility" do
      member = Suma::Fixtures.member.onboarding_verified.create
      cfg = Suma::Fixtures.anon_proxy_vendor_configuration.create
      program = Suma::Fixtures.program.create

      # No programs means everyone can access
      expect(described_class.for(member.refresh, as_of:)).to contain_exactly(
        have_attributes(configuration: be === cfg),
      )

      # Having program restricts access
      cfg.add_program(program)
      expect(described_class.for(member.refresh, as_of:)).to be_empty

      # Member can now access
      Suma::Fixtures.program_enrollment.create(program:, member:)
      expect(described_class.for(member.refresh, as_of:)).to contain_exactly(
        have_attributes(configuration: be === cfg),
      )
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

  describe "ensure_anonymous_email_contact" do
    let(:va) { Suma::Fixtures.anon_proxy_vendor_account.create }

    it "creates a new member with an anonymous email contact" do
      va.ensure_anonymous_email_contact
      expect(va.contact).to have_attributes(email: "u#{va.member.id}@example.com")
    end

    it "noops if there is already an anonymous email contact" do
      contact = Suma::Fixtures.anon_proxy_member_contact(member: va.member).email.create
      va.update(contact:)
      va.ensure_anonymous_email_contact
      expect(va.contact).to be === contact
    end
  end
end
