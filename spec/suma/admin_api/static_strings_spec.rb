# frozen_string_literal: true

require "suma/admin_api/static_strings"

RSpec.describe Suma::AdminAPI::StaticStrings, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/static_strings" do
    it "returns all static strings" do
      no_text = Suma::Fixtures.static_string.create(namespace: "n", key: "k1")
      with_text = Suma::Fixtures.static_string.text("hi", es: "hola").create(namespace: "n", key: "k2")

      get "/v1/static_strings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(1)
    end
  end

  describe "POST /v1/static_strings/create" do
    it "creates a new static string" do
    end

    it "noops if it exists" do
    end
  end

  describe "POST /v1/static_strings/update" do
    it "updates the given static strings" do
      post "/v1/roles/create", name: "testrole"

      expect(last_response).to have_status(200)
      expect(Suma::Role.all).to include(have_attributes(name: "testrole"))
    end
  end

  describe "POST /v1/static_strings/deprecate" do
    it "sets the string deprecated" do
      post "/v1/roles/create", name: "testrole"

      expect(last_response).to have_status(200)
      expect(Suma::Role.all).to include(have_attributes(name: "testrole"))
    end
  end

  describe "POST /v1/static_strings/undeprecate" do
    it "sets the string undeprecated" do
      post "/v1/roles/create", name: "testrole"

      expect(last_response).to have_status(200)
      expect(Suma::Role.all).to include(have_attributes(name: "testrole"))
    end
  end
end
