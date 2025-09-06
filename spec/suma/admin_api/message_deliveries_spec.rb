# frozen_string_literal: true

require "suma/admin_api/message_deliveries"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::MessageDeliveries, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/message_deliveries" do
    it "returns all deliveries (no bodies)" do
      deliveries = Array.new(2) { Suma::Fixtures.message_delivery.create }

      get "/v1/message_deliveries"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(deliveries))
      expect(last_response_json_body[:items][0]).to_not include(:bodies)
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/message_deliveries" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.message_delivery(to: "zzz zam com").create,
          Suma::Fixtures.message_delivery(template: "zzz zam").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.message_delivery(to: "tam tam com", template: "tam tam").create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/message_deliveries" }
      def make_item(i)
        return Suma::Fixtures.message_delivery.create(created_at: Time.now - i.hour)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/message_deliveries" }
      let(:order_by_field) { "to" }
      def make_item(i)
        return Suma::Fixtures.message_delivery.create(to: i.to_s + "@lithic.tech")
      end
    end
  end

  describe "GET /v1/message_deliveries/:id" do
    it "returns the delivery with the given ID and its bodies" do
      del = Suma::Fixtures.message_delivery.with_body.with_body.create

      get "/v1/message_deliveries/#{del.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: del.id, bodies: have_length(2))
    end

    it "403s if the delivery does not exist" do
      get "/v1/message_deliveries/0"

      expect(last_response).to have_status(403)
    end

    it "includes sensitive bodies if the admin has access" do
      admin.remove_all_roles
      admin.add_role(Suma::Role.cache.onboarding_manager)
      admin.add_role(Suma::Role.cache.sensitive_messages)

      del = Suma::Fixtures.message_delivery.
        with_body(mediatype: "subject", content: "unredacted").
        with_body(mediatype: "text/plain", content: "super sensitive").
        with_body(mediatype: "text/html", content: "<x>sensitive</x>").
        create(sensitive: true)

      get "/v1/message_deliveries/#{del.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        bodies: contain_exactly(
          include(mediatype: "subject", content: "unredacted"),
          include(mediatype: "text/plain", content: "super sensitive"),
          include(mediatype: "text/html", content: "<x>sensitive</x>"),
        ),
      )
    end

    it "includes full bodies if the delivery is not sensitive" do
      admin.remove_all_roles
      admin.add_role(Suma::Role.cache.onboarding_manager)

      del = Suma::Fixtures.message_delivery.
        with_body(mediatype: "text/plain", content: "not sensitive").
        create(sensitive: false)

      get "/v1/message_deliveries/#{del.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        bodies: contain_exactly(
          include(mediatype: "text/plain", content: "not sensitive"),
        ),
      )
    end

    it "includes redacted bodies if the admin does not have access" do
      admin.remove_all_roles
      admin.add_role(Suma::Role.cache.onboarding_manager)

      del = Suma::Fixtures.message_delivery.
        with_body(mediatype: "subject", content: "unredacted").
        with_body(mediatype: "text/plain", content: "super sensitive").
        with_body(mediatype: "text/html", content: "<x>sensitive</x>").
        create(sensitive: true)

      get "/v1/message_deliveries/#{del.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        bodies: contain_exactly(
          include(mediatype: "subject", content: "unredacted"),
          include(mediatype: "text/plain", content: "***"),
          include(mediatype: "text/html", content: "***"),
        ),
      )
    end
  end

  describe "GET /v1/message_deliveries/last" do
    it "returns the last delivery" do
      d1 = Suma::Fixtures.message_delivery.create
      d2 = Suma::Fixtures.message_delivery.create

      get "/v1/message_deliveries/last"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: d2.id)
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      get "/v1/message_deliveries/last"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "POST /v1/message_deliveries/:id/external_details" do
    let(:d) { Suma::Fixtures.message_delivery.sent.create(carrier_key: "noop_extended") }

    it "fetches details" do
      post "/v1/message_deliveries/#{d.id}/external_details"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(noop_msg_id: start_with("fixtured-"))
    end

    it "400s if there is no message id" do
      d.update(transport_message_id: nil)

      post "/v1/message_deliveries/#{d.id}/external_details"

      expect(last_response).to have_status(400)
    end

    it "400s if the carrier does not support fetching details" do
      d.update(carrier_key: "noop")

      post "/v1/message_deliveries/#{d.id}/external_details"

      expect(last_response).to have_status(400)
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/message_deliveries/#{d.id}/external_details"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    it "errors if the delivery does not exist" do
      post "/v1/message_deliveries/0/external_details"

      expect(last_response).to have_status(403)
    end
  end
end
