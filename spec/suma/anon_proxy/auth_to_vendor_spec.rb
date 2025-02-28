# frozen_string_literal: true

RSpec.describe Suma::AnonProxy::AuthToVendor, :db do
  let(:va) do
    Suma::Fixtures.anon_proxy_vendor_account.with_configuration(auth_to_vendor_key:).create
  end
  let(:auth_to_vendor_key) { raise NotImplementedError }

  shared_examples_for "an AuthToVendor" do
    it "responds to the necessary methods" do
      atv = va.auth_to_vendor
      expect { atv.needs_polling? }.to_not raise_error
      expect { atv.needs_attention? }.to_not raise_error
    end
  end

  describe "ensure_anonymous_email_contact" do
    let(:auth_to_vendor_key) { "fake" }

    it "creates a new member with an anonymous email contact" do
      va.auth_to_vendor.ensure_anonymous_email_contact
      expect(va.contact).to have_attributes(email: "u#{va.member.id}@example.com")
    end

    it "noops if there is already an anonymous email contact" do
      contact = Suma::Fixtures.anon_proxy_member_contact(member: va.member).email.create
      va.update(contact:)
      va.auth_to_vendor.ensure_anonymous_email_contact
      expect(va.contact).to be === contact
    end
  end

  describe "Fake" do
    let(:auth_to_vendor_key) { "fake" }

    it_behaves_like "an AuthToVendor"

    it "increments the call count" do
      Suma::AnonProxy::AuthToVendor::Fake.reset
      expect do
        va.auth_to_vendor.auth
      end.to change { Suma::AnonProxy::AuthToVendor::Fake.calls }.from(0).to(1)
    end
  end

  describe "Lime" do
    let(:auth_to_vendor_key) { "lime" }

    it_behaves_like "an AuthToVendor"

    it "auths by sending a magic link request to the anonymous member email" do
      contact = Suma::Fixtures.anon_proxy_member_contact(member: va.member).email("a@b.c").create
      va.update(contact:)
      req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/magic-link").
        with(
          body: {"email" => "a@b.c", "user_agreement_country_code" => "US", "user_agreement_version" => "5"},
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded",
            "X-Suma" => "holá",
          },
        ).
        to_return(status: 200, body: "", headers: {})

      va.auth_to_vendor.auth
      expect(req).to have_been_made
    end

    it "provisions a contact with an anonymous email" do
      req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/magic-link").
        to_return(status: 200, body: "", headers: {})

      va.auth_to_vendor.auth
      expect(req).to have_been_made
      expect(va.refresh.contact).to be_a(Suma::AnonProxy::MemberContact)
    end

    it "needs attention if there is no member contact" do
      expect(va.auth_to_vendor).to be_needs_attention
      va.auth_to_vendor.ensure_anonymous_email_contact
      expect(va.auth_to_vendor).to_not be_needs_attention
    end
  end

  describe "LyftPass" do
    let(:auth_to_vendor_key) { "lyft_pass" }

    before(:each) do
      Suma::Lyft.reset_configuration

      Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: 5.hours.from_now,
        data: {body: {}, cookies: {}}.to_json,
      )

      Suma::Lyft.pass_authorization = "Basic xyz"
      Suma::Lyft.pass_email = "a@b.c"
      Suma::Lyft.pass_org_id = "1234"
      Suma::Lyft.pass_program_id = "5678"
      @vendor_service_rate = Suma::Fixtures.vendor_service_rate.create
      @vendor_service = Suma::Fixtures.vendor_service.
        mobility.
        create(
          vendor: Suma::Lyft.mobility_vendor,
          mobility_vendor_adapter_key: "lyft_deeplink",
          charge_after_fulfillment: true,
        )
      @vendor_service_rate.add_service(@vendor_service)
      Suma::Lyft.pass_vendor_service_rate_id = @vendor_service_rate.id
    end

    it_behaves_like "an AuthToVendor"

    it "sends an invitation request to Lyft" do
      req = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/bulk/invite").
        to_return(status: 200)

      t = Time.now
      Timecop.freeze(t) { va.auth_to_vendor.auth }
      expect(req).to have_been_made
      expect(va).to have_attributes(registered_with_vendor: t.iso8601)
    end

    it "noops if the account is already registered" do
      va.update(registered_with_vendor: "abc")
      va.auth_to_vendor.auth
      expect(va).to have_attributes(registered_with_vendor: "abc")
    end

    it "needs attention if the user is not registered" do
      expect(va.auth_to_vendor).to be_needs_attention
      va.update(registered_with_vendor: "x")
      expect(va.auth_to_vendor).to_not be_needs_attention
    end
  end
end
