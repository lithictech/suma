# frozen_string_literal: true

require "suma/admin_api/vendible_groups"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::VendibleGroups, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/vendible_groups" do
    it "returns all vendors" do
      objs = Array.new(2) { Suma::Fixtures.vendible_group.create }

      get "/v1/vendible_groups"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/vendible_groups" }
      let(:search_term) { "Market" }

      def make_matching_items
        return [
          Suma::Fixtures.vendible_group(name: translated_text("Summer Farmers Market")).create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.vendible_group(name: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/vendible_groups" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        ordinal = 0 - i
        return Suma::Fixtures.vendible_group.create(ordinal:)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/vendible_groups" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.vendible_group.create
      end
    end
  end

  describe "POST /v1/vendible_groups/create" do
    it "creates a vendible group" do
      existing_offering = Suma::Fixtures.offering.create
      existing_vs = Suma::Fixtures.vendor_service.create
      post "/v1/vendible_groups/create",
           name: {en: "test", es: "testo"},
           commerce_offerings: [
             {
               id: existing_offering.id,
             },
           ],
           vendor_services: [
             {
               id: existing_vs.id,
             },
           ]

      expect(last_response).to have_status(200)
      expect(Suma::Vendible::Group.all).to have_length(1)
      expect(last_response).to have_json_body.that_includes(
        commerce_offerings: contain_exactly(include(id: existing_offering.id)),
        vendor_services: contain_exactly(include(id: existing_vs.id)),
      )
    end
  end

  describe "GET /v1/vendible_groups/:id" do
    it "returns the vendible group" do
      o = Suma::Fixtures.offering.create
      vs = Suma::Fixtures.vendor_service.create
      group = Suma::Fixtures.vendible_group.with_offering(o).with_vendor_service(vs).create

      get "/v1/vendible_groups/#{group.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: group.id,
        commerce_offerings: contain_exactly(include(id: o.id)),
        vendor_services: contain_exactly(include(id: vs.id)),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/vendible_groups/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/vendible_group/:id" do
    it "updates a vendible group" do
      group = Suma::Fixtures.vendible_group.create
      post "/v1/vendible_groups/#{group.id}", name: {en: "group A", es: "grupo A"}

      expect(last_response).to have_status(200)
      expect(group.refresh).to have_attributes(name: have_attributes(en: "group A"))
    end

    it "handles adding and removing nested resources" do
      offering_fac = Suma::Fixtures.offering
      offering_to_remove = offering_fac.create
      offering_to_add = offering_fac.create
      vs_fac = Suma::Fixtures.vendor_service
      vs_to_remove = vs_fac.create
      vs_to_add = vs_fac.create
      group = Suma::Fixtures.vendible_group.with_offering(offering_to_remove).with_vendor_service(vs_to_remove).create

      post "/v1/vendible_groups/#{group.id}",
           commerce_offerings: [
             {
               id: offering_to_add.id,
             },
           ],
           vendor_services: [
             {
               id: vs_to_add.id,
             },
           ]

      expect(last_response).to have_status(200)
      expect(group.refresh.commerce_offerings).to contain_exactly(
        have_attributes(id: offering_to_add.id),
      )
      expect(group.refresh.vendor_services).to contain_exactly(
        have_attributes(id: vs_to_add.id),
      )
    end
  end
end
