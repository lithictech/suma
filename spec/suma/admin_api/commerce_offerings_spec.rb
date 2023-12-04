# frozen_string_literal: true

require "suma/admin_api/commerce_offerings"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::CommerceOfferings, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/commerce_offerings" do
    it "returns all offerings" do
      objs = Array.new(2) { Suma::Fixtures.offering.create }

      get "/v1/commerce_offerings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/commerce_offerings" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.offering(description: translated_text("zim")).create,
          Suma::Fixtures.offering(description: translated_text("ZIM zam")).create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.offering(description: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/commerce_offerings" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.offering.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/commerce_offerings" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.offering.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/commerce_offerings/create" do
    it "creates the offering" do
      photo_file = File.open("spec/data/images/photo.png", "rb")
      image = Rack::Test::UploadedFile.new(photo_file, "image/png", true)

      post "/v1/commerce_offerings/create",
           image: image,
           description: {en: "EN test", es: "ES test"},
           fulfillment_prompt: {en: "EN prompt", es: "ES prompt"},
           fulfillment_confirmation: {en: "EN confirmation", es: "ES confirmation"},
           fulfillment_options: {
             "0" => {
               description: {en: "EN description", es: "ES description"},
               type: "delivery",
               address: {
                 address1: "test st",
                 city: "Portland",
                 state_or_province: "Oregon",
                 postal_code: "97209",
               },
             },
             "1" => {
               description: {en: "EN description", es: "ES description"},
               type: "pickup",
             },
           },
           opens_at: "2023-07-01T00:00:00-0700",
           closes_at: "2023-10-01T00:00:00-0700"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Commerce::Offering.all).to have_length(1)
      off = Suma::Commerce::Offering.first
      expect(off).to have_attributes(
        period_begin: match_time("2023-07-01T00:00:00-0700"),
        period_end: match_time("2023-10-01T00:00:00-0700"),
      )
      expect(off.fulfillment_options).to have_length(2)
      expect(off.fulfillment_options[0]).to have_attributes(address: be_present, ordinal: 0)
      expect(off.fulfillment_options[1]).to have_attributes(address: be_nil, ordinal: 1)
    end
  end

  describe "GET /v1/commerce_offerings/:id" do
    it "returns the offering" do
      order = Suma::Fixtures.order.as_purchased_by(admin).create
      e = Suma::Fixtures.eligibility_constraint.create
      o = order.checkout.cart.offering
      o.add_eligibility_constraint(e)

      get "/v1/commerce_offerings/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: o.id,
        orders: have_length(1),
        offering_products: have_length(1),
        eligibility_constraints: have_length(1),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/commerce_offerings/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/commerce_offerings/:id" do
    it "updates the offering" do
      photo_file = File.open("spec/data/images/photo.png", "rb")
      image = Rack::Test::UploadedFile.new(photo_file, "image/png", true)
      o = Suma::Fixtures.offering.create
      post "/v1/commerce_offerings/#{o.id}",
           image: image,
           description: {en: "EN test", es: "ES test"},
           fulfillment_options: {
             "0" => {
               description: {en: "EN desc", es: "ES desc"},
               type: "pickup",
             },
           }

      expect(last_response).to have_status(200)
      expect(o.refresh).to have_attributes(
        description: have_attributes(en: "EN test"),
        fulfillment_options: contain_exactly(have_attributes(description: have_attributes(en: "EN desc"))),
      )
    end
  end

  describe "POST /v1/commerce_offering/:id/eligibilities" do
    it "modify offering eligibilities" do
      existing_constraint = Suma::Fixtures.eligibility_constraint.create
      o = Suma::Fixtures.offering.with_constraints(existing_constraint).create
      new_eligibility = Suma::Fixtures.eligibility_constraint.create

      post "/v1/commerce_offerings/#{o.id}/eligibilities", constraint_ids: [new_eligibility.id]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(eligibility_constraints: contain_exactly(include(id: new_eligibility.id)))
    end

    it "403s if eligibility constraint does not exist" do
      o = Suma::Fixtures.offering.create

      post "/v1/commerce_offerings/#{o.id}/eligibilities", constraint_ids: [0]

      expect(last_response).to have_status(403)
    end
  end

  describe "GET /v1/commerce_offering/:id/picklist" do
    it "returns item pick list of offering orders" do
      order = Suma::Fixtures.order.as_purchased_by(admin).create
      o = order.checkout.cart.offering
      pick_list = o.order_pick_list

      get "/v1/commerce_offerings/#{o.id}/picklist"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*pick_list))
    end
    it "403s if offering does not exist" do
      get "/v1/commerce_offerings/0/picklist"

      expect(last_response).to have_status(403)
    end
  end
end
