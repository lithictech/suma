# frozen_string_literal: true

require "suma/admin_api/anon_proxy_vendor_accounts"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::AnonProxyVendorAccounts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/anon_proxy_vendor_accounts" do
    it "returns all anon proxy vendor accounts" do
      objs = Array.new(2) { Suma::Fixtures.anon_proxy_vendor_account.create }

      get "/v1/anon_proxy_vendor_accounts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/anon_proxy_vendor_accounts" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.anon_proxy_vendor_account.with_access_code("zzz  123").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.anon_proxy_vendor_account.with_access_code("not magic").create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/anon_proxy_vendor_accounts" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.anon_proxy_vendor_account.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/anon_proxy_vendor_accounts" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.anon_proxy_vendor_account.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "GET /v1/anon_proxy_vendor_accounts/:id" do
    it "returns the anon proxy vendor account" do
      config = Suma::Fixtures.anon_proxy_vendor_configuration.create
      member = Suma::Fixtures.member.create
      member_contact = Suma::Fixtures.anon_proxy_member_contact(email: "a@b.c", member:).create
      va = Suma::Fixtures.anon_proxy_vendor_account.with_configuration(config).with_contact(member_contact).create

      get "/v1/anon_proxy_vendor_accounts/#{va.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: va.id,
        configuration: include(id: config.id),
        contact: include(id: member_contact.id),
      )
    end
  end

  describe "POST /v1/anon_proxy_vendor_accounts/:id/destroy" do
    it "destroys the resource" do
      m = Suma::Fixtures.anon_proxy_vendor_account.create

      post "/v1/anon_proxy_vendor_accounts/#{m.id}/destroy"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: m.id)
      expect(m).to be_destroyed
    end
  end
end
