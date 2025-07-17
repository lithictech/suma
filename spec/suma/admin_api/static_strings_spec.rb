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
        that_includes(items: include(
          namespace: "n",
          strings: contain_exactly(
            hash_including(key: "k1", en: ""),
            hash_including(key: "k2", en: "hi"),
          ),
        ))
    end
  end

  describe "POST /v1/static_strings/create" do
    it "creates a new static string" do
      post "/v1/static_strings/create", namespace: "x", key: "y"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(namespace: "x", key: "y", en: "", deprecated: false)

      expect(Suma::I18n::StaticString.all).to contain_exactly(have_attributes(key: "y"))
    end

    it "noops if it exists" do
      Suma::Fixtures.static_string.text("hi").create(namespace: "x", key: "y")
      post "/v1/static_strings/create", namespace: "x", key: "y"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(key: "y", en: "hi")
    end
  end

  describe "POST /v1/static_strings/update" do
    it "updates the given static strings (no text)" do
      Suma::Fixtures.static_string.create(namespace: "x", key: "y")

      post "/v1/static_strings/update", namespace: "x", key: "y", en: "hi"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(key: "y", en: "hi")
    end

    it "updates the given static strings (existing text)" do
      Suma::Fixtures.static_string.text.create(namespace: "x", key: "y")

      post "/v1/static_strings/update", namespace: "x", key: "y", en: "hi"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(key: "y", en: "hi")
    end
  end

  describe "POST /v1/static_strings/deprecate" do
    it "sets the string deprecated" do
      Suma::Fixtures.static_string.text.create(namespace: "x", key: "y")

      post "/v1/static_strings/deprecate", namespace: "x", key: "y"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(deprecated: true)
    end
  end

  describe "POST /v1/static_strings/undeprecate" do
    it "sets the string undeprecated" do
      Suma::Fixtures.static_string.text.create(namespace: "x", key: "y", deprecated: true)

      post "/v1/static_strings/undeprecate", namespace: "x", key: "y"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(deprecated: false)
    end
  end
end
