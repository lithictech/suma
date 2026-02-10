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

    it "applies eligibility" do
      member = Suma::Fixtures.member.onboarding_verified.create
      cfg = Suma::Fixtures.anon_proxy_vendor_configuration.create
      program = Suma::Fixtures.program.create
      cfg.add_program(program)

      # No requirement means everyone can access
      expect(described_class.for(member.refresh, as_of:)).to contain_exactly(
        have_attributes(configuration: be === cfg),
      )

      # Having requirement restricts access
      attribute = Suma::Fixtures.eligibility_attribute.create
      Suma::Fixtures.eligibility_requirement.attribute(attribute).create(resource: program)
      expect(described_class.for(member.refresh, as_of:)).to be_empty

      # Member can now access
      Suma::Fixtures.eligibility_assignment.create(attribute:, member:)
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

  describe "ensure_anonymous_contact" do
    let(:va) { Suma::Fixtures.anon_proxy_vendor_account.create }
    let(:phone) { "15552223333" }

    it "creates a new member with an anonymous email contact" do
      Suma::AnonProxy::Relay::FakeEmail.provisioned_external_id = "xyz"
      va.ensure_anonymous_contact(:email)
      expect(va.contact).to have_attributes(
        email: /u#{va.member.id}\.\d+@example.com/,
        relay_key: "fake-email-relay",
        external_relay_id: "xyz",
      )
    ensure
      Suma::AnonProxy::Relay::FakeEmail.provisioned_external_id = nil
    end

    it "noops if there is already an anonymous email contact" do
      contact = Suma::Fixtures.anon_proxy_member_contact(member: va.member).email.create
      va.update(contact:)
      va.ensure_anonymous_contact(:email)
      expect(va.contact).to be === contact
    end

    it "creates a new member with an anonymous phone contact" do
      va.ensure_anonymous_contact(:phone)
      # Phone format matches Relay::FakePhone logic
      expect(va.contact).to have_attributes(phone: "1555#{va.member.id}".ljust(11, "1"))
    end

    it "noops if there is already an anonymous phone contact" do
      contact = Suma::Fixtures.anon_proxy_member_contact(member: va.member).phone.create
      va.update(contact:)
      va.ensure_anonymous_contact(:phone)
      expect(va.contact).to be === contact
    end
  end

  describe "ui state helpers" do
    let(:member) { Suma::Fixtures.member.create }
    let(:vendor) { Suma::Fixtures.vendor.create }
    let!(:vendor_service_rate) { Suma::Fixtures.vendor_service_rate.create(surcharge_cents: 200) }
    let!(:vendor_service) { Suma::Fixtures.vendor_service.create(vendor:) }
    let!(:vc) { Suma::Fixtures.anon_proxy_vendor_configuration.create(vendor:) }
    let!(:va) { Suma::Fixtures.anon_proxy_vendor_account(configuration: vc, member:).create }
    let!(:program) { Suma::Fixtures.program.with_(vc).create }
    let!(:attribute) { Suma::Fixtures.eligibility_attribute.between(member, program).create }
    let!(:pricing) { Suma::Fixtures.program_pricing.create(program:, vendor_service_rate:, vendor_service:) }
    let(:as_of) { Time.now }

    describe "require_payment_instrument?" do
      it "is true if the configuration vendor has a program pricing with a nonzero rate" do
        expect(va).to be_require_payment_instrument(as_of:)
      end

      describe "is false when" do
        it "the rate is zero" do
          vendor_service_rate.update(surcharge_cents: 0)
          expect(va).to_not be_require_payment_instrument(as_of:)
        end

        it "the program is inactive" do
          program.update(period_begin: 1.year.ago, period_end: 1.day.ago)
          expect(va).to_not be_require_payment_instrument(as_of:)
        end

        it "there are no same-vendor services linked to pricings in the vendor config programs" do
          vendor_service.update(vendor: Suma::Fixtures.vendor.create)
          expect(va).to_not be_require_payment_instrument(as_of:)
        end

        it "the member cannot access the programs with pricings" do
          Suma::Eligibility::Assignment.dataset.delete
          expect(va).to_not be_require_payment_instrument(as_of:)
        end
      end
    end

    describe "ui_state_v1" do
      let!(:card) { Suma::Fixtures.card.member(member).create }

      it "represents the link state" do
        expect(va.ui_state_v1(now: as_of)).to have_attributes(
          index_card_mode: :link,
          needs_linking: true,
          requires_payment_method: true,
          has_payment_method: true,
        )
      end

      it "represents the relink state" do
        va.auth_to_vendor.auth
        expect(va.ui_state_v1(now: as_of)).to have_attributes(
          index_card_mode: :relink,
          needs_linking: false,
          requires_payment_method: true,
          has_payment_method: true,
        )
      end

      it "represents the payment state" do
        va.auth_to_vendor.auth
        card.soft_delete
        expect(va.ui_state_v1(now: as_of)).to have_attributes(
          index_card_mode: :payment,
          needs_linking: false,
          requires_payment_method: true,
          has_payment_method: false,
        )
      end
    end
  end
end
