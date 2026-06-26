# frozen_string_literal: true

require "suma/admin_api/marketing_lists"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::MarketingLists, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  it_behaves_like "an endpoint with subroutes for related resources" do
    let(:detail_route) do
      "/v1/marketing_lists/#{Suma::Fixtures.marketing_list.create.id}"
    end
  end

  describe "GET /v1/marketing_lists" do
    it "returns all objects" do
      u = Array.new(2) { Suma::Fixtures.marketing_list.create }

      get "/v1/marketing_lists"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/marketing_lists" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.marketing_list(label: "zim zzz zom").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.marketing_list(label: "wibble wobble").create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/marketing_lists" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.marketing_list.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/marketing_lists" }
      let(:order_by_field) { "label" }
      def make_item(i)
        return Suma::Fixtures.marketing_list.create(label: i.to_s)
      end
    end
  end

  describe "POST /v1/marketing_lists/create" do
    it "creates the object" do
      post "/v1/marketing_lists/create", label: "hello"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(label: "hello")
    end
  end

  describe "GET /v1/marketing_lists/:id" do
    it "returns the object" do
      o = Suma::Fixtures.marketing_list.create

      get "/v1/marketing_lists/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the item does not exist" do
      get "/v1/marketing_lists/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/marketing_lists/:id" do
    it "updates the object" do
      m1 = Suma::Fixtures.member.create
      m2 = Suma::Fixtures.member.create
      m3 = Suma::Fixtures.member.create
      o = Suma::Fixtures.marketing_list.members(m1, m2).create

      post "/v1/marketing_lists/#{o.id}", label: "hello", members: [{id: m2.id}, {id: m3.id}]

      expect(last_response).to have_status(200)
      expect(o.refresh).to have_attributes(label: "hello")
      expect(o.members).to have_same_ids_as(m2, m3)
    end

    it "errors if the list is managed" do
      o = Suma::Fixtures.marketing_list.create(managed: true)

      post "/v1/marketing_lists/#{o.id}", label: "hello"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "marketing_list_managed"))
    end
  end

  describe "POST /v1/marketing_lists/:id/rebuild" do
    it "rebuilds the list" do
      m1 = Suma::Fixtures.member.create
      m1.message_preferences!
      o = Suma::Fixtures.marketing_list.create(label: "Unverified, All time - SMS", managed: true)

      post "/v1/marketing_lists/#{o.id}/rebuild"

      expect(last_response).to have_status(200)
      expect(o.refresh.members).to have_same_ids_as(m1)
    end

    it "errors if the list is unmanaged" do
      o = Suma::Fixtures.marketing_list.create

      post "/v1/marketing_lists/#{o.id}/rebuild"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "marketing_list_unmanaged"))
    end

    it "errors if the list has no spec" do
      o = Suma::Fixtures.marketing_list.create(label: "No spec", managed: true)

      post "/v1/marketing_lists/#{o.id}/rebuild"

      expect(last_response).to have_json_body.that_includes(error: include(code: "marketing_list_spec_missing"))
    end
  end

  describe "POST /v1/marketing_lists/:id/upload_csv" do
    it "updates the members" do
      m1 = Suma::Fixtures.member.create(phone: "15552223333")
      m2 = Suma::Fixtures.member.create(email: "a@b.c")
      m3 = Suma::Fixtures.member.create

      csv_str = "#{m1.us_phone},#{m2.email}\n#{m3.id},garbage\n000,x@y.z\n"
      attachment = in_memory_rack_file(csv_str, "text/csv")

      o = Suma::Fixtures.marketing_list.create

      post "/v1/marketing_lists/#{o.id}/upload_csv", file: attachment

      expect(last_response).to have_status(200)
      expect(o.members).to have_same_ids_as(m1, m2, m3)
    end

    it "errors if the list is managed" do
      attachment = in_memory_rack_file("", "text/csv")

      o = Suma::Fixtures.marketing_list.create(managed: true)

      post "/v1/marketing_lists/#{o.id}/upload_csv", file: attachment

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "marketing_list_managed"))
    end
  end
end
