# frozen_string_literal: true

require "suma/admin_api/payment_triggers"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::PaymentTriggers, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  it_behaves_like "an endpoint with subroutes for related resources" do
    let(:detail_route) do
      "/v1/payment_triggers/#{Suma::Fixtures.payment_trigger.create.id}"
    end
  end

  describe "GET /v1/payment_triggers" do
    it "returns all objects" do
      u = Array.new(2) { Suma::Fixtures.payment_trigger.create }

      get "/v1/payment_triggers"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/payment_triggers" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.payment_trigger(memo: translated_text("zzz zam zom")).create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.payment_trigger(memo: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/payment_triggers" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.payment_trigger.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/payment_triggers" }
      let(:order_by_field) { "label" }
      def make_item(i)
        return Suma::Fixtures.payment_trigger.create(label: i.to_s)
      end
    end
  end

  describe "GET /v1/payment_triggers/:id" do
    it "returns the object" do
      o = Suma::Fixtures.payment_trigger.create

      get "/v1/payment_triggers/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "includes trigger executions" do
      o = Suma::Fixtures.payment_trigger.with_execution.create

      get "/v1/payment_triggers/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: o.id, executions: include(items: have_length(1)))
    end

    it "403s if the item does not exist" do
      get "/v1/payment_triggers/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/payment_triggers/create" do
    it "creates the trigger" do
      orig = Suma::Fixtures.ledger.create

      post "/v1/payment_triggers/create",
           label: "hi",
           active_during: [],
           match_multiplier: 2.5,
           unmatched_amount_cents: 500,
           maximum_cumulative_subsidy_cents: 500,
           memo: {en: "hello", es: "hola"},
           originating_ledger: {id: orig.id},
           receiving_ledger_name: "Subsidy",
           receiving_ledger_contribution_text: {en: "Memo En", es: "Memo Es"}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Payment::Trigger[id: last_response_json_body[:id]]).to have_attributes(
        label: "hi",
        active_during: [],
        match_multiplier: 2.5,
        maximum_cumulative_subsidy_cents: 500,
        memo: have_attributes(en: "hello"),
        originating_ledger: be === orig,
        receiving_ledger_name: "Subsidy",
        receiving_ledger_contribution_text: have_attributes(en: "Memo En"),
      )
    end
  end

  describe "POST /v1/payment_triggers/:id" do
    it "updates the object" do
      o = Suma::Fixtures.payment_trigger.create

      post "/v1/payment_triggers/#{o.id}", label: "test"

      expect(last_response).to have_status(200)
      expect(o.refresh).to have_attributes(label: "test")
    end

    it "can set active_during the object" do
      o = Suma::Fixtures.payment_trigger.create
      period = Time.at(1)..Time.at(100)

      post "/v1/payment_triggers/#{o.id}", active_during: [{begin: period.begin, end: period.end}]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        active_during: contain_exactly(include(start: match_time(period.begin), end: match_time(period.end))),
      )
      expect(o.refresh).to have_attributes(
        active_during: contain_exactly(have_attributes(begin: match_time(period.begin), end: match_time(period.end))),
      )
    end
  end
end
