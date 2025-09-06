# frozen_string_literal: true

require "suma/admin_api/commerce_offerings"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::CommerceOfferings, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
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
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.offering(description: translated_text("zzz")).create,
          Suma::Fixtures.offering(description: translated_text("ZIM zzz")).create,
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
           image:,
           description: {en: "EN test", es: "ES test"},
           fulfillment_prompt: {en: "EN prompt", es: "ES prompt"},
           fulfillment_instructions: {en: "", es: ""},
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
           period_begin: "2023-07-01T00:00:00-0700",
           period_end: "2023-10-01T00:00:00-0700"

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

    it "handles the fulfillment_options_doemptyarray: param" do
      photo_file = File.open("spec/data/images/photo.png", "rb")
      image = Rack::Test::UploadedFile.new(photo_file, "image/png", true)

      post "/v1/commerce_offerings/create",
           image:,
           description: {en: "EN test", es: "ES test"},
           fulfillment_prompt: {en: "EN prompt", es: "ES prompt"},
           fulfillment_instructions: {en: "", es: ""},
           fulfillment_confirmation: {en: "EN confirmation", es: "ES confirmation"},
           fulfillment_options_doemptyarray: true,
           period_begin: "2023-07-01T00:00:00-0700",
           period_end: "2023-10-01T00:00:00-0700"

      expect(last_response).to have_status(200)
      expect(Suma::Commerce::Offering.first).to have_attributes(fulfillment_options: be_empty)
    end
  end

  describe "GET /v1/commerce_offerings/:id" do
    it "returns the offering" do
      order = Suma::Fixtures.order.as_purchased_by(admin).create
      o = order.checkout.cart.offering

      get "/v1/commerce_offerings/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: o.id,
        orders: have_length(1),
        offering_products: have_length(1),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/commerce_offerings/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/commerce_offerings/:id" do
    let(:photo_file) { File.open("spec/data/images/photo.png", "rb") }
    let(:image) { Rack::Test::UploadedFile.new(photo_file, "image/png", true) }
    let(:o) { Suma::Fixtures.offering.create }

    it "updates the offering" do
      new_period_begin = Time.parse("2023-12-10T08:00:00-0700")
      new_period_end = Time.parse("2023-12-15T05:00:00-0700")
      post "/v1/commerce_offerings/#{o.id}",
           image:,
           description: {en: "EN test", es: "ES test"},
           fulfillment_options: {
             "0" => {
               description: {en: "EN desc", es: "ES desc"},
               type: "pickup",
             },
           },
           period_begin: new_period_begin,
           period_end: new_period_end

      expect(last_response).to have_status(200)
      expect(o.refresh).to have_attributes(
        description: have_attributes(en: "EN test"),
        fulfillment_options: contain_exactly(have_attributes(description: have_attributes(en: "EN desc"))),
        period_begin: new_period_begin,
        period_end: new_period_end,
      )
    end

    it "handles create/remove/update of nested resources" do
      to_remove = Suma::Fixtures.offering_fulfillment_option.create
      to_update = Suma::Fixtures.offering_fulfillment_option.create
      o = Suma::Fixtures.offering.with_fulfillment(to_remove).with_fulfillment(to_update).create
      post "/v1/commerce_offerings/#{o.id}",
           fulfillment_options: {
             "0" => {
               id: to_update.id,
               description: {en: "EN updated", es: "ES updated"},
               type: "pickup",
             },
             "1" => {
               description: {en: "EN added", es: "ES added"},
               type: "pickup",
             },
           }

      expect(last_response).to have_status(200)
      expect(to_remove).to be_destroyed
      expect(o.refresh.fulfillment_options).to contain_exactly(
        have_attributes(id: to_update.id, ordinal: 0, description: have_attributes(en: "EN updated")),
        have_attributes(ordinal: 1, description: have_attributes(en: "EN added")),
      )
    end

    it "handles the fulfillment_options_doemptyarray: param" do
      o = Suma::Fixtures.offering.with_fulfillment.create

      post "/v1/commerce_offerings/#{o.id}", fulfillment_options_doemptyarray: true

      expect(last_response).to have_status(200)
      expect(o.refresh.fulfillment_options).to be_empty
    end

    it "handles create/remove/update of sub-nested resources" do
      address = Suma::Fixtures.address.create
      remove = Suma::Fixtures.offering_fulfillment_option.create(address:)
      update = Suma::Fixtures.offering_fulfillment_option.create(address:)
      add = Suma::Fixtures.offering_fulfillment_option.create
      o = Suma::Fixtures.offering.with_fulfillment(remove).with_fulfillment(update).create

      post "/v1/commerce_offerings/#{o.id}",
           fulfillment_options: {
             "0" => {
               id: remove.id,
               description: {en: "EN address to be removed", es: "ES address to be removed"},
               type: "pickup",
             },
             "1" => {
               id: update.id,
               description: {en: "EN address to be updated", es: "ES address to be updated"},
               type: "pickup",
               address: {
                 address1: "updated st",
                 city: "Portland",
                 state_or_province: "Oregon",
                 postal_code: "97209",
               },
             },
             "2" => {
               id: add.id,
               description: {en: "EN address to be added", es: "ES address to be added"},
               type: "pickup",
               address: {
                 address1: "new st",
                 city: "Portland",
                 state_or_province: "Oregon",
                 postal_code: "97209",
               },
             },
           }

      expect(last_response).to have_status(200)
      expect(o.refresh.fulfillment_options).to contain_exactly(
        have_attributes(id: remove.id, address: be_nil),
        have_attributes(id: update.id, address: include(address1: "updated st")),
        have_attributes(id: add.id, address: include(address1: "new st")),
      )
    end

    it "errors with a 409 if a foreign key constraint is violated" do
      ful_opt = Suma::Fixtures.offering_fulfillment_option.create
      offering = Suma::Fixtures.offering.with_fulfillment(ful_opt).create
      Suma::Fixtures.checkout.with_fulfillment_option(ful_opt).create

      post "/v1/commerce_offerings/#{offering.id}", fulfillment_options: {}

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.that_includes(error: include(message: /could not be removed/))
    end
  end

  describe "POST /v1/commerce_offering/:id/programs" do
    it "modifies programs" do
      existing_program = Suma::Fixtures.program.create
      o = Suma::Fixtures.offering.with_programs(existing_program).create
      new_program = Suma::Fixtures.program.create

      post "/v1/commerce_offerings/#{o.id}/programs", program_ids: [new_program.id]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(programs: have_same_ids_as(new_program))
    end

    it "403s if program does not exist" do
      o = Suma::Fixtures.offering.create

      post "/v1/commerce_offerings/#{o.id}/programs", program_ids: [0]

      expect(last_response).to have_status(403)
    end
  end

  describe "GET /v1/commerce_offering/:id/picklist" do
    it "returns order item pick list for an offering" do
      order = Suma::Fixtures.order.as_purchased_by(admin).create
      o = order.checkout.cart.offering

      get "/v1/commerce_offerings/#{o.id}/picklist"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        order_items: match_array(
          hash_including(:member, :fulfillment_option, quantity: 1, offering_product: hash_including(:product)),
        ),
      )
    end

    it "403s if offering does not exist" do
      get "/v1/commerce_offerings/0/picklist"

      expect(last_response).to have_status(403)
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      get "/v1/commerce_offerings/1/picklist"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end
end
