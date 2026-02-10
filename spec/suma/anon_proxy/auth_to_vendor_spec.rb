# frozen_string_literal: true

RSpec.describe Suma::AnonProxy::AuthToVendor, :db do
  let(:va) do
    Suma::Fixtures.anon_proxy_vendor_account.with_configuration(auth_to_vendor_key:).create
  end
  let(:member) { va.member }
  let(:auth_to_vendor_key) { raise NotImplementedError }
  let(:now) { Time.now }

  shared_examples_for "an AuthToVendor" do
    it "responds to the necessary methods" do
      atv = va.auth_to_vendor
      expect { atv.needs_polling? }.to_not raise_error
      expect { atv.needs_linking?(now: Time.now) }.to_not raise_error
    end
  end

  describe "Fake" do
    let(:auth_to_vendor_key) { "fake" }

    it_behaves_like "an AuthToVendor"

    it "increments the call count" do
      Suma::AnonProxy::AuthToVendor::Fake.reset
      expect do
        va.auth_to_vendor.auth(now:)
      end.to change { Suma::AnonProxy::AuthToVendor::Fake.calls }.from(0).to(1)
    end

    it "provisions a contact with an anonymous email" do
      va.auth_to_vendor.auth(now:)
      expect(va.refresh.contact).to be_a(Suma::AnonProxy::MemberContact)
      expect(va.registrations).to contain_exactly(have_attributes(external_program_id: va.contact.email))
    end

    it "needs attention if there is no member contact" do
      expect(va.auth_to_vendor).to be_needs_linking(now: Time.now)
      va.ensure_anonymous_contact(:email)
      expect(va.auth_to_vendor).to_not be_needs_linking(now: Time.now)
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

      va.auth_to_vendor.auth(now:)
      expect(req).to have_been_made
      expect(va.registrations).to contain_exactly(have_attributes(external_program_id: "a@b.c"))
    end

    it "provisions a contact with an anonymous email" do
      req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/magic-link").
        to_return(status: 200, body: "", headers: {})

      va.auth_to_vendor.auth(now:)
      expect(req).to have_been_made
      expect(va.refresh.contact).to be_a(Suma::AnonProxy::MemberContact)
    end

    it "needs attention if there is no member contact" do
      expect(va.auth_to_vendor).to be_needs_linking(now: Time.now)
      va.ensure_anonymous_contact(:email)
      expect(va.auth_to_vendor).to_not be_needs_linking(now: Time.now)
    end

    describe "exchange_magic_link_token" do
      it "exchanges the link token for an auth token" do
        req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/login").
          with(
            body: {
              "has_virtual_card" => "false",
              "magic_link_token" => "mytoken",
              "user_agreement_country_code" => "US",
              "user_agreement_version" => "5",
            },
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded",
              "X-Suma" => "holá",
            },
          ).
          to_return(fixture_response("lime/app_post_magic_link"))

        token = va.auth_to_vendor.exchange_magic_link_token("mytoken")
        expect(req).to have_been_made
        expect(token).to eq("ey123.ey456.789")
      end

      it "raises an error if the response does not include a 'token' key" do
        req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/login").
          to_return(json_response({}))

        expect do
          va.auth_to_vendor.exchange_magic_link_token("mytoken")
        end.to raise_error(Suma::AnonProxy::AuthToVendor::Lime::NoToken, /HttpError\(status: 200/)
        expect(req).to have_been_made
      end
    end

    describe "log_out" do
      it "calls Lime" do
        req = stub_request(:post, "https://web-production.lime.bike/api/rider/v1/logout").
          with(
            headers: {
              "Authorization" => "Bearer ey123.ey456.789",
              "Content-Type" => "application/x-www-form-urlencoded",
              "X-Suma" => "holá",
            },
          ).
          to_return(status: 200, body: "", headers: {})
        va.auth_to_vendor.log_out("ey123.ey456.789")
        expect(req).to have_been_made
      end
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
    end

    it_behaves_like "an AuthToVendor"

    it "sends an invitation request to Lyft for each program the user has available" do
      req = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/bulk/invite").
        to_return(status: 200)

      Timecop.freeze("2022-12-15T12:00:15Z") do
        # Enroll only in the program the user is in, with a lyft pass program id
        not_available = Suma::Fixtures.program.create(lyft_pass_program_id: "12")
        Suma::Fixtures.eligibility_requirement.create(resource: not_available)
        available = Suma::Fixtures.program.create(lyft_pass_program_id: "34")
        va.auth_to_vendor.auth(now:)
      end
      expect(req).to have_been_made
      expect(va.registrations).to contain_exactly(have_attributes(external_program_id: "34"))
    end

    it "noops if there are no programs" do
      Suma::ExternalCredential.dataset.delete
      va.auth_to_vendor.auth(now:)
      expect(va.registrations).to be_empty
    end

    it "does not re-register the account if the member already registered with that program" do
      req = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/bulk/invite").
        to_return(status: 200)

      Timecop.freeze("2020-01-15T12:00:00Z") do
        Suma::Fixtures.program.create(lyft_pass_program_id: "34")
        Suma::Fixtures.program.create(lyft_pass_program_id: "56")
        va.add_registration(external_program_id: "34")
        va.auth_to_vendor.auth(now:)
      end
      expect(req).to have_been_made
      expect(va.registrations).to contain_exactly(
        have_attributes(external_program_id: "34"),
        have_attributes(external_program_id: "56"),
      )
    end

    it "needs attention if the user is not registered in an available program" do
      expect(va.auth_to_vendor).to_not be_needs_linking(now:)

      Suma::Fixtures.program.create(lyft_pass_program_id: "5678")
      expect(va.auth_to_vendor).to be_needs_linking(now:)
      va.add_registration(external_program_id: "5678")
      expect(va.auth_to_vendor).to_not be_needs_linking(now:)

      Suma::Fixtures.program.create(lyft_pass_program_id: "1234")
      expect(va.auth_to_vendor).to be_needs_linking(now:)
    end
  end
end
