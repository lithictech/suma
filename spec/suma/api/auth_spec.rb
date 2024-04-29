# frozen_string_literal: true

require "suma/api/auth"

RSpec.describe Suma::API::Auth, :db, reset_configuration: Suma::Member do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }

  let(:email) { "jane@farmers.org" }
  let(:other_email) { "diff-" + email }
  let(:password) { "1234abcd!" }
  let(:other_password) { password + "abc" }
  let(:name) { "David Graeber" }
  let(:phone) { "1234567890" }
  let(:full_phone) { "11234567890" }
  let(:other_phone) { "1234567999" }
  let(:other_full_phone) { "11234567999" }
  let(:fmt_phone) { "(123) 456-7890" }
  let(:timezone) { "America/Juneau" }
  let(:member_params) do
    {name:, email:, phone:, password:, timezone:}
  end
  let(:member_create_params) { member_params.merge(phone: full_phone) }

  describe "POST /v1/auth/start" do
    it "errors if a member is already authed" do
      c = Suma::Fixtures.member.create
      login_as(c)

      post("/v1/auth/start", phone: "(222) 333-4444", timezone:)

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "You are already signed in. Please sign out first."))
    end

    describe "when the phone number does not exist" do
      it "creates a member with the given phone number and dispatches an SMS" do
        post("/v1/auth/start", phone: "(222) 333-4444", timezone:)

        expect(last_response).to have_status(200)
        expect(last_response).to have_session_cookie.with_no_extra_keys
        expect(Suma::Member.all).to contain_exactly(have_attributes(phone: "12223334444"))
        member = Suma::Member.first
        expect(member.reset_codes).to contain_exactly(have_attributes(transport: "sms"))
      end

      it "marks terms agreed if sent" do
        post("/v1/auth/start", phone: "(222) 333-4444", timezone:, terms_agreed: true)

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(requires_terms_agreement: false)
        expect(Suma::Member.first).to have_attributes(terms_agreed: Suma::Member::LATEST_TERMS_PUBLISH_DATE)
      end

      it "does not mark terms agreed if not sent" do
        post("/v1/auth/start", phone: "(222) 333-4444", timezone:)

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(requires_terms_agreement: true)
        expect(Suma::Member.first).to have_attributes(terms_agreed: be_nil)
      end

      it "creates a activity" do
        post("/v1/auth/start", phone: "(222) 333-4444", timezone:)

        expect(last_response).to have_status(200)
        expect(Suma::Member.last.activities).to contain_exactly(have_attributes(message_name: "registered"))
      end

      it "sets the language" do
        post "/v1/auth/start", phone: "(222) 333-4444", timezone:, language: "es"

        expect(last_response).to have_status(200)
        expect(Suma::Member.last.message_preferences!).to have_attributes(preferred_language: "es")
      end
    end

    describe "when the phone number belongs to a member" do
      it "dispatches an SMS" do
        existing = Suma::Fixtures.member(phone: "12223334444").create

        post("/v1/auth/start", phone: "(222) 333-4444", timezone:)

        expect(last_response).to have_status(200)
        expect(last_response).to have_session_cookie.with_no_extra_keys
        expect(Suma::Member.all).to contain_exactly(be === existing)
        expect(existing.reset_codes).to contain_exactly(have_attributes(transport: "sms"))
      end

      it "does not create an activity" do
        c = Suma::Fixtures.member(phone: full_phone).create

        post("/v1/auth/start", phone: c.phone, timezone:)

        expect(last_response).to have_status(200)
        expect(Suma::Member::Activity.all).to be_empty
      end

      it "does not modify terms agreed since consent to changes was not explicit" do
        member = Suma::Fixtures.member(phone: "12223334444").create

        post("/v1/auth/start", phone: "(222) 333-4444", timezone:, terms_agreed: true)

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(requires_terms_agreement: true)
        # For a login, we do not set the terms agreed, since even though we show the 'you access our terms' message
        # we need explicit approval somewhere else.
        expect(member.refresh).to have_attributes(terms_agreed: be_nil)
      end

      it "sets the language" do
        c = Suma::Fixtures.member(phone: full_phone).create

        post "/v1/auth/start", phone: full_phone, timezone:, language: "es"

        expect(last_response).to have_status(200)
        expect(c.refresh.message_preferences!).to have_attributes(preferred_language: "es")
      end
    end
  end

  describe "POST /v1/auth/verify" do
    it "errors if a member is already authed" do
      c = Suma::Fixtures.member.create
      login_as(c)

      post("/v1/auth/verify", phone: "(222) 333-4444", token: "abc")

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "You are already signed in. Please sign out first."))
    end

    it "returns 200 and creates a session if the phone number and OTP are valid" do
      c = Suma::Fixtures.member(phone: full_phone).create
      code = Suma::Fixtures.reset_code(member: c).sms.create

      post("/v1/auth/verify", phone: c.phone, token: code.token)

      expect(last_response).to have_status(200)
      expect(last_response).to have_session_cookie.with_payload_key("warden.user.member.key")
      expect(last_response).to have_json_body.
        that_includes(id: c.id, phone: fmt_phone)
      expect(code.refresh).to be_expired
    end

    it "returns a 200 and creates a session if the member exists and skip verification is configured" do
      c = Suma::Fixtures.member.create
      Suma::Member.skip_verification_allowlist = ["*"]

      post("/v1/auth/verify", phone: c.phone, token: "abc")

      expect(last_response).to have_status(200)
      expect(last_response).to have_session_cookie.with_payload_key("warden.user.member.key")
    end

    it "returns a 200 and onboards user if configured" do
      c = Suma::Fixtures.member.create
      Suma::Member.onboard_allowlist = ["*"]

      post("/v1/auth/verify", phone: c.phone, token: "abc")

      expect(last_response).to have_status(200)
      expect(last_response).to have_session_cookie.with_payload_key("warden.user.member.key")
      expect(c.refresh).to have_attributes(
        onboarding_verified?: true,
        roles: [],
      )
    end

    it "returns a 200 and handles superadmin promotion configured" do
      c = Suma::Fixtures.member.create
      Suma::Member.superadmin_allowlist = ["*"]

      post("/v1/auth/verify", phone: c.phone, token: "abc")

      expect(last_response).to have_status(200)
      expect(last_response).to have_session_cookie.with_payload_key("warden.user.member.key")
      expect(c.refresh).to have_attributes(
        onboarding_verified?: true,
        roles: include(Suma::Role.admin_role),
      )
    end

    it "returns 403 if the phone number does not map to a member" do
      code = Suma::Fixtures.reset_code.sms.create

      post("/v1/auth/verify", phone: "15551112222", token: code.token)

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "invalid_otp"))
    end

    it "returns 403 if the OTP is not valid for the phone number" do
      code = Suma::Fixtures.reset_code.sms.create
      code.expire!

      post("/v1/auth/verify", phone: code.member.phone, token: code.token)

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "invalid_otp"))
    end
  end

  describe "DELETE /v1/auth" do
    it "removes the cookies" do
      delete "/v1/auth"

      expect(last_response).to have_status(204)
      expect(last_response["Set-Cookie"]).to include("=deleted; path=/; expires=Thu, 01 Jan 1970 00:00:00")
      expect(last_response["Clear-Site-Data"]).to eq("*")
    end
  end

  describe "POST /v1/auth/contact_list" do
    it "errors if a member is already authed" do
      c = Suma::Fixtures.member.create
      login_as(c)

      post("/v1/auth/contact_list", name: "Obama", phone: "(222) 333-4444", timezone:, channel: "instagram")

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "You are already signed in. Please sign out first."))
    end

    describe "when the phone number does not exist" do
      it "creates a member and referral with the given phone number and parameters" do
        post("/v1/auth/contact_list", name: "Obama", phone: "(222) 333-4444", timezone:, channel: "instagram",
                                      event_name: "marketplace_event_123",)

        expect(last_response).to have_status(200)
        expect(Suma::Member.all).to contain_exactly(have_attributes(name: "Obama", phone: "12223334444"))
        expect(Suma::Member::Referral.last).to have_attributes(member_id: Suma::Member.last.id)
        expect(Suma::Member::Activity.last.summary).to eq("Created from referral API")
      end

      it "sets the language" do
        post("/v1/auth/contact_list", name: "Obama", phone: "(222) 333-4444", timezone:, channel: "instagram",
                                      language: "es",)

        expect(last_response).to have_status(200)
        expect(Suma::Member.last.message_preferences!).to have_attributes(preferred_language: "es")
      end
    end

    describe "when phone number exists" do
      it "creates a member activity for contact list sign up" do
        m = Suma::Fixtures.member.create(phone: 12_223_334_444)
        post("/v1/auth/contact_list", name: "Obama", phone: "(222) 333-4444", timezone:, channel: "instagram",
                                      event_name: "marketplace_event_123",)
        summary = "Added to contact list (channel: instagram, event_name: marketplace_event_123)"
        expect(m.activities.last).to have_attributes(summary:)
        expect(last_response).to have_status(200)
      end

      it "does not update member" do
        m = Suma::Fixtures.member.create(phone: 12_223_334_455, name: "Amabo")
        post("/v1/auth/contact_list", name: "Obama", phone: "(222) 333-4444", timezone:, channel: "instagram")

        expect(last_response).to have_status(200)
        expect(m).to have_attributes(phone: "12223334455", name: "Amabo")
      end

      it "does not create new member referral" do
        Suma::Fixtures.member.create(phone: 12_223_334_444)
        post("/v1/auth/contact_list", name: "Obama", phone: "(222) 333-4444", timezone:, channel: "instagram")

        expect(last_response).to have_status(200)
        expect(Suma::Member::Referral.all.count).to be(0)
      end
    end

    describe "with an organization name" do
      it "adds a membership if the org exists" do
        org = Suma::Fixtures.organization.create
        post("/v1/auth/contact_list", name: "Obama", phone: "(222) 333-4444", timezone:, channel: "instagram",
                                      organization_name: org.name,)

        expect(last_response).to have_status(200)
        expect(org.unverified_memberships).to contain_exactly(have_attributes(member: have_attributes(name: "Obama")))
      end

      it "noops if the org does not exist" do
        me = Suma::Fixtures.member.create
        post("/v1/auth/contact_list", name: "Obama", phone: me.phone, timezone:, channel: "instagram",
                                      organization_name: "abcd",)

        expect(last_response).to have_status(200)
        expect(me.all_organization_memberships).to be_empty
      end
    end
  end
end
