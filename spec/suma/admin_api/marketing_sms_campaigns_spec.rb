# frozen_string_literal: true

require "suma/admin_api/marketing_sms_campaigns"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::MarketingSmsCampaigns, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/marketing_sms_campaigns" do
    it "returns all objects" do
      u = Array.new(2) { Suma::Fixtures.marketing_sms_campaign.create }

      get "/v1/marketing_sms_campaigns"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/marketing_sms_campaigns" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.marketing_sms_campaign(label: "zim zam zom").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.marketing_sms_campaign(label: "wibble wobble").create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/marketing_sms_campaigns" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.marketing_sms_campaign.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/marketing_sms_campaigns" }
      let(:order_by_field) { "label" }
      def make_item(i)
        return Suma::Fixtures.marketing_sms_campaign.create(label: i.to_s)
      end
    end
  end

  describe "GET /v1/marketing_sms_campaigns/:id" do
    it "returns the object" do
      o = Suma::Fixtures.marketing_sms_campaign.create

      get "/v1/marketing_sms_campaigns/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the item does not exist" do
      get "/v1/marketing_sms_campaigns/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/marketing_sms_campaigns/create" do
    it "creates the object" do
      post "/v1/marketing_sms_campaigns/create", label: "hi"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Marketing::SmsCampaign[id: last_response_json_body[:id]]).to have_attributes(
        label: "hi",
      )
    end
  end

  describe "POST /v1/marketing_sms_campaigns/:id" do
    it "updates the object" do
      o = Suma::Fixtures.marketing_sms_campaign.create

      post "/v1/marketing_sms_campaigns/#{o.id}", label: "test", body: {en: "entext", es: "estext"}

      expect(last_response).to have_status(200)
      expect(o.refresh).to have_attributes(label: "test", body: have_attributes(en: "entext", es: "estext"))
    end

    it "replaces the lists" do
      o = Suma::Fixtures.marketing_sms_campaign.create
      oldlist = Suma::Fixtures.marketing_list.create
      o.add_list(oldlist)

      newlist1 = Suma::Fixtures.marketing_list.create
      newlist2 = Suma::Fixtures.marketing_list.create

      post "/v1/marketing_sms_campaigns/#{o.id}", lists: [{id: newlist1.id}, {id: newlist2.id}]

      expect(last_response).to have_status(200)
      expect(o.refresh.lists).to contain_exactly(be === newlist1, be === newlist2)
    end
  end

  describe "POST /v1/marketing_sms_campaigns/:id/send" do
    it "sends the campaign" do
      o = Suma::Fixtures.marketing_sms_campaign.create

      post "/v1/marketing_sms_campaigns/#{o.id}/send"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
      expect(o.refresh).to be_sent
    end

    it "403s if the resource does not exist" do
      post "/v1/marketing_sms_campaigns/0/send"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/marketing_sms_campaigns/preview" do
    it "previews the given body" do
      admin.update(name: "jose")

      post "/v1/marketing_sms_campaigns/preview", en: "hi {{name}}", es: "hola {{name}}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(en: "hi jose")
    end
  end
end
