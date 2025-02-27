# frozen_string_literal: true

RSpec.describe Suma::AnonProxy::AuthToVendor, :db do
  describe "Http" do
    let(:va) do
      Suma::Fixtures.anon_proxy_vendor_account.with_configuration(
        auth_to_vendor_key: "http",
        auth_url: "https://x.y",
        auth_http_method: "POST",
        auth_headers: {"X-Y" => "b"},
      ).create
    end

    it "can auth by making an HTTP request" do
      req = stub_request(:post, "https://x.y/").
        with(
          body: "{\"email\":\"\",\"phone\":\"\"}",
          headers: {"X-Y" => "b"},
        ).
        to_return(status: 200, body: "")

      va.auth_to_vendor
      expect(req).to have_been_made
    end

    describe "auth_request" do
      it "returns the auth fields for the configuration" do
        atp = described_class.create!("http", vendor_account: va)
        expect(atp.auth_request).to include(
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
        atp = described_class.create!("http", vendor_account: va)
        expect(atp.auth_request).to include(
          body: '{"email":"x@y.z","phone":"12223334444"}',
        )
      end

      it "errors if fields on the vendor config are not set" do
        atp = described_class.create!("http", vendor_account: va)

        va.configuration.auth_http_method = ""
        expect { atp.auth_request }.to raise_error(/configuration auth_http_method must be set/)
        va.configuration.auth_http_method = "POST"

        va.configuration.auth_url = ""
        expect { atp.auth_request }.to raise_error(/configuration auth_url must be set/)
        va.configuration.auth_url = "https://x.y/"
      end
    end
  end

  describe "Fake" do
    let(:va) do
      Suma::Fixtures.anon_proxy_vendor_account.with_configuration(auth_to_vendor_key: "fake").create
    end

    it "increments the call count" do
      Suma::AnonProxy::AuthToVendor::Fake.reset
      expect do
        va.auth_to_vendor
      end.to change { Suma::AnonProxy::AuthToVendor::Fake.calls }.from(0).to(1)
    end
  end

  describe "LyftPass" do
    let(:va) do
      Suma::Fixtures.anon_proxy_vendor_account.with_configuration(auth_to_vendor_key: "lyft_pass").create
    end

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

      va.auth_to_vendor
      expect(req).to have_been_made
    end
  end
end
