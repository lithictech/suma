# frozen_string_literal: true

require "suma/admin_api/roles"

RSpec.describe Suma::AdminAPI::Roles, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/roles" do
    it "returns all roles" do
      c = Suma::Role.create(name: "c")
      d = Suma::Role.create(name: "d")
      b = Suma::Role.create(name: "b")

      get "/v1/roles"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(Suma::Role.order(:name).all).ordered)
    end
  end

  describe "POST /v1/roles/create" do
    it "creates a role" do
      post "/v1/roles/create", name: "testrole"

      expect(last_response).to have_status(200)
      expect(Suma::Role.all).to include(have_attributes(name: "testrole"))
    end
  end

  describe "GET /v1/roles/:id" do
    it "returns the role" do
      m = Suma::Role.create(name: "spam")

      get "/v1/roles/#{m.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: m.id)
    end

    it "403s if the item does not exist" do
      get "/v1/roles/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/roles/:id" do
    it "updates a role" do
      v = Suma::Role.create(name: "spam")

      post "/v1/roles/#{v.id}", name: "test"

      expect(last_response).to have_status(200)
      expect(v.refresh).to have_attributes(name: "test")
    end
  end
end
