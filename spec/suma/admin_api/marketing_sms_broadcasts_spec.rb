# frozen_string_literal: true

require "suma/admin_api/marketing_sms_broadcasts"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::MarketingSmsBroadcasts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/marketing_sms_broadcasts" do
    it "returns all objects" do
      u = Array.new(2) { Suma::Fixtures.marketing_sms_broadcast.create }

      get "/v1/marketing_sms_broadcasts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/marketing_sms_broadcasts" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.marketing_sms_broadcast(label: "zim zam zom").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.marketing_sms_broadcast(label: "wibble wobble").create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/marketing_sms_broadcasts" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.marketing_sms_broadcast.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/marketing_sms_broadcasts" }
      let(:order_by_field) { "label" }
      def make_item(i)
        return Suma::Fixtures.marketing_sms_broadcast.create(label: i.to_s)
      end
    end
  end

  describe "GET /v1/marketing_sms_broadcasts/:id" do
    it "returns the object" do
      o = Suma::Fixtures.marketing_sms_broadcast.create

      get "/v1/marketing_sms_broadcasts/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the item does not exist" do
      get "/v1/marketing_sms_broadcasts/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/marketing_sms_broadcasts/create" do
    it "creates the object" do
      post "/v1/marketing_sms_broadcasts/create", label: "hi"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Marketing::SmsBroadcast[id: last_response_json_body[:id]]).to have_attributes(
        label: "hi",
        created_by: be === admin,
      )
    end
  end

  describe "POST /v1/marketing_sms_broadcasts/:id" do
    it "updates the object" do
      o = Suma::Fixtures.marketing_sms_broadcast.create

      post "/v1/marketing_sms_broadcasts/#{o.id}", label: "test", body: {en: "entext", es: "estext"}

      expect(last_response).to have_status(200)
      expect(o.refresh).to have_attributes(label: "test", body: have_attributes(en: "entext", es: "estext"))
    end

    it "replaces the lists" do
      o = Suma::Fixtures.marketing_sms_broadcast.create
      oldlist = Suma::Fixtures.marketing_list.create
      o.add_list(oldlist)

      newlist1 = Suma::Fixtures.marketing_list.create
      newlist2 = Suma::Fixtures.marketing_list.create

      post "/v1/marketing_sms_broadcasts/#{o.id}", lists: [{id: newlist1.id}, {id: newlist2.id}]

      expect(last_response).to have_status(200)
      expect(o.refresh.lists).to contain_exactly(be === newlist1, be === newlist2)
    end
  end

  describe "POST /v1/marketing_sms_broadcasts/:id/send" do
    it "sends the broadcast", :no_transaction_check do
      o = Suma::Fixtures.marketing_sms_broadcast.create

      post "/v1/marketing_sms_broadcasts/#{o.id}/send"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
      expect(o.refresh).to be_sent
    end

    it "403s if the resource does not exist" do
      post "/v1/marketing_sms_broadcasts/0/send"

      expect(last_response).to have_status(403)
    end
  end

  describe "GET /v1/marketing_sms_broadcasts/:id/review" do
    it "returns the pre-review info" do
      o = Suma::Fixtures.marketing_sms_broadcast.create

      get "/v1/marketing_sms_broadcasts/#{o.id}/review"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        broadcast: include(id: o.id),
        total_cost: "0.0",
        total_recipients: 0,
      )
    end

    it "returns the post-review info" do
      o = Suma::Fixtures.marketing_sms_broadcast.create(sent_at: Time.now)

      get "/v1/marketing_sms_broadcasts/#{o.id}/review"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        broadcast: include(id: o.id),
        actual_cost: "0.0",
      )
    end

    it "403s if the resource does not exist" do
      get "/v1/marketing_sms_broadcasts/0/review"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/marketing_sms_broadcasts/preview" do
    it "previews the given body" do
      admin.update(name: "jose")

      post "/v1/marketing_sms_broadcasts/preview", en: "hi {{name}}", es: "hola {{name}}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        en: "hi jose",
        en_payload: include(characters: 7),
      )
    end
  end
end
