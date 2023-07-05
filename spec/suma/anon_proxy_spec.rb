# frozen_string_literal: true

RSpec.describe Suma::AnonProxy, :db do
  describe "VendorAccount" do
    let(:described_class) { Suma::AnonProxy::VendorAccount }

    describe "::for" do
      it "returns existing enabled vendor accounts and creates new for configured vendors" do
        member = Suma::Fixtures.member.create
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
            provider_key: "fake",
          )
        end

        it "noops for an existing member contact" do
          mc = Suma::Fixtures.anon_proxy_member_contact.email.create(member: va.member)
          c = va.provision_contact
          expect(c).to be === mc
        end
      end
    end
  end
end