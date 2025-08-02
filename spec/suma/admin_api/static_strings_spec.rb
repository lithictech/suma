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
            hash_including(id: no_text.id, key: "k1", en: ""),
            hash_including(id: with_text.id, key: "k2", en: "hi"),
          ),
        ))
    end

    it "sorts deprecated strings last" do
      c = Suma::Fixtures.static_string.create(namespace: "n", key: "c")
      a = Suma::Fixtures.static_string.create(namespace: "n", key: "a")
      d = Suma::Fixtures.static_string.create(namespace: "n", key: "d", deprecated: true)
      b = Suma::Fixtures.static_string.create(namespace: "n", key: "b", deprecated: true)

      get "/v1/static_strings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: include(
          namespace: "n",
          strings: match_array(
            [
              hash_including(id: a.id),
              hash_including(id: c.id),
              hash_including(id: b.id),
              hash_including(id: d.id),
            ],
          ),
        ))
    end
  end

  describe "POST /v1/static_strings/create" do
    it "creates a new static string" do
      expect(Suma::I18n::StaticStringRebuilder).to receive(:notify_change)

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

  describe "POST /v1/static_strings/:id/update" do
    it "updates the given static strings (no existing text)" do
      expect(Suma::I18n::StaticStringRebuilder).to receive(:notify_change)

      ss = Suma::Fixtures.static_string.create(modified_at: 3.hours.ago)

      post "/v1/static_strings/#{ss.id}/update", en: "hi"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(en: "hi")
      expect(ss.refresh).to have_attributes(modified_at: match_time(:now))
    end

    it "updates the given static strings (existing text)" do
      ss = Suma::Fixtures.static_string.text.create

      post "/v1/static_strings/#{ss.id}/update", en: "hi"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(en: "hi")
    end

    it "does not replace missing localized params" do
      ss = Suma::Fixtures.static_string.text("hi", es: "hola").create

      post "/v1/static_strings/#{ss.id}/update", en: "bye"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(en: "bye", es: "hola")
    end

    it "can explicitly set empty" do
      ss = Suma::Fixtures.static_string.text("hi", es: "hola").create

      post "/v1/static_strings/#{ss.id}/update", en: ""

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(en: "", es: "hola")
    end
  end

  describe "POST /v1/static_strings/:id/deprecate" do
    it "sets the string deprecated" do
      expect(Suma::I18n::StaticStringRebuilder).to receive(:notify_change)

      ss = Suma::Fixtures.static_string.text.create(modified_at: 3.hours.ago)

      post "/v1/static_strings/#{ss.id}/deprecate"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(deprecated: true)
      expect(ss.refresh).to have_attributes(modified_at: match_time(:now))
    end
  end

  describe "POST /v1/static_strings/undeprecate" do
    it "sets the string undeprecated" do
      expect(Suma::I18n::StaticStringRebuilder).to receive(:notify_change)

      ss = Suma::Fixtures.static_string.text.create(deprecated: true, modified_at: 3.hours.ago)

      post "/v1/static_strings/#{ss.id}/undeprecate"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(deprecated: false)
      expect(ss.refresh).to have_attributes(modified_at: match_time(:now))
    end
  end
end
