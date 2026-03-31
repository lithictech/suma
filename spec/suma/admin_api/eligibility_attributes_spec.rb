# frozen_string_literal: true

require "suma/admin_api/eligibility_attributes"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::EligibilityAttributes, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/eligibility_attributes" do
    it "returns all rows" do
      objs = Array.new(2) { Suma::Fixtures.eligibility_attribute.create }

      get "/v1/eligibility_attributes"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/eligibility_attributes" }
      let(:search_term) { "zzz" }

      def make_matching_items = [Suma::Fixtures.eligibility_attribute.create(name: "zzz")]
      def make_non_matching_items = [Suma::Fixtures.eligibility_attribute.create(name: "wibble")]
    end
  end

  describe "POST /v1/eligibility_attributes/create" do
    it "creates the instance" do
      post "/v1/eligibility_attributes/create", name: "attr1"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Eligibility::Attribute.all).to have_length(1)
    end
  end

  describe "GET /v1/eligibility_attributes/:id" do
    it "returns the instance" do
      attr = Suma::Fixtures.eligibility_attribute.create

      get "/v1/eligibility_attributes/#{attr.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: attr.id)
    end

    it "403s if the item does not exist" do
      get "/v1/eligibility_attributes/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/eligibility_attributes/:id" do
    it "can update the name" do
      attr = Suma::Fixtures.eligibility_attribute.create

      post "/v1/eligibility_attributes/#{attr.id}", name: "foo"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(name: "foo")
    end
  end
end
