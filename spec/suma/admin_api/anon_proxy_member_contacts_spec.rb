# frozen_string_literal: true

require "suma/admin_api/anon_proxy_member_contacts"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::AnonProxyMemberContacts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/anon_proxy_member_contacts" do
    it "returns all anon proxy vendor accounts" do
      objs = Array.new(2) { Suma::Fixtures.anon_proxy_member_contact.create }

      get "/v1/anon_proxy_member_contacts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/anon_proxy_member_contacts" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.anon_proxy_member_contact.create(email: "zzz  123"),
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.anon_proxy_member_contact.create(email: "not magic"),
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/anon_proxy_member_contacts" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.anon_proxy_member_contact.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/anon_proxy_member_contacts" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.anon_proxy_member_contact.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/anon_proxy_member_contacts/provision" do
    let(:member) { Suma::Fixtures.member.create }

    it "provisions a new member contact of the given type" do
      post "/v1/anon_proxy_member_contacts/provision", member: {id: member.id}, type: :email

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(email: /u#{member.id}\.\d+@example.com/)
      expect(member.anon_proxy_contacts).to have_length(1)
    end

    it "errors if the member does not exist" do
      post "/v1/anon_proxy_member_contacts/provision", member: {id: 0}, type: :email

      expect(last_response).to have_status(403)
    end
  end

  describe "GET /v1/anon_proxy_member_contacts/:id" do
    it "returns the resource" do
      mc = Suma::Fixtures.anon_proxy_member_contact.create

      get "/v1/anon_proxy_member_contacts/#{mc.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: mc.id)
    end
  end

  describe "POST /v1/anon_proxy_member_contacts/:id" do
    it "updates the resource" do
      mc = Suma::Fixtures.anon_proxy_member_contact.create

      post "/v1/anon_proxy_member_contacts/#{mc.id}", email: "a@b.c"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: mc.id, email: "a@b.c")
    end
  end

  describe "POST /v1/anon_proxy_member_contacts/:id/destroy" do
    it "destroys the resource" do
      m = Suma::Fixtures.anon_proxy_member_contact.create

      post "/v1/anon_proxy_member_contacts/#{m.id}/destroy"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: m.id)
      expect(m).to be_destroyed
    end
  end
end
