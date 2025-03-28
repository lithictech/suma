# frozen_string_literal: true

require "suma/admin_api/programs"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Programs, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/programs" do
    it "returns all programs" do
      objs = Array.new(2) { Suma::Fixtures.program.create }

      get "/v1/programs"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/programs" }
      let(:search_term) { "zibble" }

      def make_matching_items
        return [
          Suma::Fixtures.program(name: translated_text("zibble zabble")).create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.program(name: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/programs" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        ordinal = 0 - i
        return Suma::Fixtures.program.create(ordinal:)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/programs" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.program.create
      end
    end
  end

  describe "POST /v1/program/create" do
    it "creates a program" do
      photo_file = File.open("spec/data/images/photo.png", "rb")
      image = Rack::Test::UploadedFile.new(photo_file, "image/png", true)
      offering = Suma::Fixtures.offering.create
      vendor_service = Suma::Fixtures.vendor_service.create

      post "/v1/programs/create",
           image:,
           name: {en: "test", es: "examen"},
           description: {en: "a description", es: "una descripcion"},
           app_link: "/food/1",
           app_link_text: {en: "View program page", es: "View program page ES"},
           period_begin: "2024-07-01T00:00:00-0700",
           period_end: "2024-10-01T00:00:00-0700",
           commerce_offerings: {
             "0" => {
               id: offering.id,
             },
           },
           vendor_services: {
             "0" => {
               id: vendor_service.id,
             },
           }

      expect(last_response).to have_status(200)
      expect(Suma::Program.all).to have_length(1)
      expect(last_response).to have_json_body.that_includes(
        commerce_offerings: contain_exactly(include(id: offering.id)),
        vendor_services: contain_exactly(include(id: vendor_service.id)),
      )
    end
  end

  describe "GET /v1/programs/:id" do
    it "returns the program" do
      o = Suma::Fixtures.offering.create
      vs = Suma::Fixtures.vendor_service.create
      program = Suma::Fixtures.program.with_offering(o).with_vendor_service(vs).create

      get "/v1/programs/#{program.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: program.id,
        commerce_offerings: contain_exactly(include(id: o.id)),
        vendor_services: contain_exactly(include(id: vs.id)),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/programs/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/programs/:id" do
    it "updates a program" do
      program = Suma::Fixtures.program.create
      post "/v1/programs/#{program.id}", name: {en: "pwb program", es: "pwb programa"}

      expect(last_response).to have_status(200)
      expect(program.refresh).to have_attributes(name: have_attributes(en: "pwb program"))
    end

    it "handles adding and removing nested resources" do
      offering_fac = Suma::Fixtures.offering
      offering_to_remove = offering_fac.create
      offering_to_add = offering_fac.create
      vs_fac = Suma::Fixtures.vendor_service
      vs_to_remove = vs_fac.create
      vs_to_add = vs_fac.create
      program = Suma::Fixtures.program.with_offering(offering_to_remove).with_vendor_service(vs_to_remove).create

      post "/v1/programs/#{program.id}",
           commerce_offerings: {
             "0" => {
               id: offering_to_add.id,
             },
           },
           vendor_services: {
             "0" => {
               id: vs_to_add.id,
             },
           }

      expect(last_response).to have_status(200)
      expect(program.refresh.commerce_offerings).to contain_exactly(
        have_attributes(id: offering_to_add.id),
      )
      expect(program.refresh.vendor_services).to contain_exactly(
        have_attributes(id: vs_to_add.id),
      )
    end
  end
end
