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
      expect(last_response).to have_json_body.that_includes(id: o.id, executions: have_length(1))
    end

    it "403s if the item does not exist" do
      get "/v1/payment_triggers/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/payment_triggers/create" do
    it "creates the trigger" do
      orig = Suma::Fixtures.ledger.create
      period = 2.days.ago..3.days.from_now

      post "/v1/payment_triggers/create",
           label: "hi",
           active_during_begin: period.begin,
           active_during_end: period.end,
           match_multiplier: 2.5,
           maximum_cumulative_subsidy_cents: 500,
           memo: {en: "hello", es: "hola"},
           originating_ledger: {id: orig.id},
           receiving_ledger_name: "Subsidy",
           receiving_ledger_contribution_text: {en: "Memo En", es: "Memo Es"}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Payment::Trigger[id: last_response_json_body[:id]]).to have_attributes(
        label: "hi",
        active_during_begin: match_time(period.begin),
        active_during_end: match_time(period.end),
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
  end

  describe "POST /v1/payment_triggers/:id/programs" do
    it "replaces the programs" do
      pr = Suma::Fixtures.program.create
      to_add = Suma::Fixtures.program.create
      pt = Suma::Fixtures.payment_trigger.with_programs(pr).create

      post "/v1/payment_triggers/#{pt.id}/programs", {program_ids: [to_add.id]}

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: pt.id)
      expect(last_response).to have_json_body.
        that_includes(programs: contain_exactly(include(id: to_add.id)))
    end

    it "403s if the program does not exist" do
      pt = Suma::Fixtures.payment_trigger.create

      post "/v1/payment_triggers/#{pt.id}/programs", {program_ids: [0]}

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/payment_triggers/:id/subdivide" do
    it "subdivides the trigger" do
      pt = Suma::Fixtures.payment_trigger.create(
        active_during: Time.parse("2024-04-01T00:00:00Z")..Time.parse("2024-04-20T00:00:00Z"),
      )

      post "/v1/payment_triggers/#{pt.id}/subdivide", amount: 2, unit: "week"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: pt.id)
      expect(Suma::Payment::Trigger.all).to have_length(2)
    end

    it "403s if the trigger does not exist" do
      post "/v1/payment_triggers/0/subdivide", amount: 1, unit: "day"

      expect(last_response).to have_status(403)
    end
  end
end
