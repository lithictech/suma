# frozen_string_literal: true

RSpec.describe Suma::AnonProxy::AuthToVendor, :db do
  let(:va) do
    Suma::Fixtures.anon_proxy_vendor_account.with_configuration(auth_to_vendor_key:).create
  end
  let(:auth_to_vendor_key) { raise NotImplementedError }

  describe "Fake" do
    let(:auth_to_vendor_key) { "fake" }

    it "increments the call count" do
      Suma::AnonProxy::AuthToVendor::Fake.reset
      expect do
        va.auth_to_vendor.auth
      end.to change { Suma::AnonProxy::AuthToVendor::Fake.calls }.from(0).to(1)
    end
  end

  describe "Lime" do
    let(:auth_to_vendor_key) { "lime" }

    it "auths by making an HTTP request" do
      req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/magic-link").
        with(
          body: {"email" => va.member.email, "user_agreement_country_code" => "US", "user_agreement_version" => "5"},
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded",
            "X-Suma" => "holá",
          },
        ).
        to_return(status: 200, body: "", headers: {})

      va.auth_to_vendor.auth
      expect(req).to have_been_made
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

    it "sends an invitation request to Lyft" do
      req = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/bulk/invite").
        to_return(status: 200)

      va.auth_to_vendor.auth
      expect(req).to have_been_made
    end
  end
end
