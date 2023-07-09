# frozen_string_literal: true

require "suma/api/anon_proxy"

RSpec.describe Suma::API::AnonProxy, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.onboarding_verified.create }
  let(:fac) { Suma::Fixtures.bank_account.member(member) }

  before(:each) do
    login_as(member)
  end

  describe "GET /v1/anon_proxy/vendor_accounts" do
    it "returns vendor accounts" do
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).create
      vc = Suma::Fixtures.anon_proxy_vendor_configuration.create

      get "/v1/anon_proxy/vendor_accounts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: contain_exactly(
          include(id: va.id),
          include(vendor_slug: vc.vendor.slug),
        ))
    end

    it "can use a default address in formatted instructions" do
      instructions = Suma::TranslatedText.create(en: "see this: %{address}")
      Suma::Fixtures.anon_proxy_vendor_configuration.create(instructions:)

      get "/v1/anon_proxy/vendor_accounts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: contain_exactly(include(instructions: "see this: ")))
    end
  end

  describe "POST /v1/anon_proxy/vendor_accounts/:id/configure" do
    let(:configuration) { Suma::Fixtures.anon_proxy_vendor_configuration.email.create }
    let!(:va) { Suma::Fixtures.anon_proxy_vendor_account(member:, configuration:).create }

    it "403s if the account does not belong to the member" do
      va.update(member: Suma::Fixtures.member.create)

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(message: match(/No anonymous proxy/)))
    end

    it "409s if the configuration is not enabled" do
      configuration.update(enabled: false)

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.that_includes(error: include(message: match(/config is not enabled/)))
    end

    it "provisions the email or phone number member contact" do
      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: va.id, all_vendor_accounts: have_same_ids_as(va))

      expect(va.refresh.contact).to have_attributes(email: "u#{member.id}@example.com")
    end

    it "noops if the account is already configured" do
      contact = Suma::Fixtures.anon_proxy_member_contact(member:).email.create
      va.update(contact:)

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: va.id, all_vendor_accounts: have_same_ids_as(va))

      expect(va.refresh.contact).to be === contact
    end

    it "formats the account address instructions" do
      contact = Suma::Fixtures.anon_proxy_member_contact(member:).email("x@y.z").create
      va.update(contact:)
      configuration.update(instructions: Suma::TranslatedText.create(en: "see this: %{address}"))

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(instructions: "see this: x@y.z")
    end
  end
end
