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

  describe "POST /v1/anon_proxy/vendor_accounts/poll_for_new_access_codes", reset_configuration: Suma::AnonProxy do
    before(:each) do
      # If any test is slow, it's because we're hitting this unexpectedly
      Suma::AnonProxy.access_code_poll_timeout = 10
      Suma::AnonProxy.access_code_poll_interval = 0
    end

    def params(*vas)
      latest_vendor_account_ids_and_access_codes = vas.map do |va|
        {id: va.id, latest_access_code: va.latest_access_code}
      end
      return {latest_vendor_account_ids_and_access_codes:}
    end

    it "can find when an account changes from a null to present access code" do
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).create
      expect(Kernel).to receive(:sleep) do
        va.replace_access_code("hello").save_changes
      end

      post "/v1/anon_proxy/vendor_accounts/poll_for_new_access_codes", params(va)

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(found_change: true, items: contain_exactly(include(id: va.id, latest_access_code: "hello")))
    end

    it "can find when an account changes from one to another access code" do
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).with_access_code("abc").create
      expect(Kernel).to receive(:sleep) do
        va.replace_access_code("def").save_changes
      end

      post "/v1/anon_proxy/vendor_accounts/poll_for_new_access_codes", params(va)

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(found_change: true, items: contain_exactly(include(id: va.id, latest_access_code: "def")))
    end

    it "only looks for vendor accounts belonging to the member" do
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).create
      other_va = Suma::Fixtures.anon_proxy_vendor_account.create
      expect(Kernel).to receive(:sleep) do
        other_va.replace_access_code("def").save_changes
        # Advance forward to defeat polling
        Timecop.travel(40.seconds.from_now)
      end

      Timecop.freeze do
        post "/v1/anon_proxy/vendor_accounts/poll_for_new_access_codes", params(va, other_va)
      end

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(found_change: false, items: [])
    end

    it "only looks for vendor accounts with recently updated access codes" do
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).with_access_code("abc", 1.hour.ago).create
      expect(Kernel).to receive(:sleep) do
        Timecop.travel(40.seconds.from_now)
      end

      j = params(va)
      # The client sees nil access codes once they're old, so that's what they send over.
      j[:latest_vendor_account_ids_and_access_codes][0][:latest_access_code] = nil

      Timecop.freeze do
        post "/v1/anon_proxy/vendor_accounts/poll_for_new_access_codes", j
      end

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(found_change: false, items: [])
    end

    it "times out after polling" do
      Suma::AnonProxy.access_code_poll_interval = 2
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).create
      expect(Kernel).to receive(:sleep).exactly(5).times do |x|
        Timecop.travel(x.seconds.from_now)
      end

      Timecop.freeze do
        post "/v1/anon_proxy/vendor_accounts/poll_for_new_access_codes", params(va)
      end

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(found_change: false, items: [])
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
