# frozen_string_literal: true

require "suma/admin_api/vendor_services"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::VendorServices, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/vendor_services" do
    it "returns all vendor services" do
      objs = Array.new(2) { Suma::Fixtures.vendor_service.create }

      get "/v1/vendor_services"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/vendor_services" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.vendor_service(internal_name: "zzz Mobility Deeplink").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.vendor_service(internal_name: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/vendor_services" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.vendor_service.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/vendor_services" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.vendor_service.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/vendor_services/create" do
    let(:photo_file) { File.open("spec/data/images/photo.png", "rb") }
    let(:image) { Rack::Test::UploadedFile.new(photo_file, "image/png", true) }

    it "creates a model" do
      post "/v1/vendor_services/create",
           vendor: {id: Suma::Fixtures.vendor.create.id},
           image:,
           image_caption: {en: "testen", es: "testes"},
           internal_name: "testint",
           external_name: "testext",
           period_begin: "2024-07-01T00:00:00-0700",
           period_end: "2024-10-01T00:00:00-0700"

      expect(last_response).to have_status(200)
      expect(Suma::Vendor::Service.all).to have_length(1)
      expect(last_response).to have_json_body.that_includes(external_name: "testext")
    end

    it "can create a model with a mobility adapter" do
      post "/v1/vendor_services/create",
           vendor: {id: Suma::Fixtures.vendor.create.id},
           image:,
           image_caption: {en: "testen", es: "testes"},
           internal_name: "testint",
           external_name: "testext",
           period_begin: "2024-07-01T00:00:00-0700",
           period_end: "2024-10-01T00:00:00-0700",
           mobility_adapter_setting: "deep_linking_suma_receipts"

      expect(last_response).to have_status(200)
      expect(Suma::Vendor::Service.first).to have_attributes(mobility_adapter: be_present)
    end
  end

  describe "GET /v1/vendor_services/:id" do
    it "returns the vendor service" do
      vendor = Suma::Fixtures.vendor.create
      service = Suma::Fixtures.vendor_service.create(vendor:)
      pricing = Suma::Fixtures.program_pricing.create(vendor_service: service)

      get "/v1/vendor_services/#{service.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: service.id,
        vendor: include(id: vendor.id),
        program_pricings: have_same_ids_as(pricing),
      )
    end

    it "returns a mobility service" do
      service = Suma::Fixtures.vendor_service.mobility_maas.create

      get "/v1/vendor_services/#{service.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: service.id,
        categories: contain_exactly(include(name: "Mobility")),
        mobility_adapter_setting: "internal",
      )
    end

    it "403s if the item does not exist" do
      get "/v1/vendor_services/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/vendor_services/:id" do
    it "updates a vendor service" do
      v = Suma::Fixtures.vendor_service.create
      photo_file = File.open("spec/data/images/photo.png", "rb")
      image = Rack::Test::UploadedFile.new(photo_file, "image/png", true)

      post "/v1/vendor_services/#{v.id}",
           external_name: "test",
           image:,
           period_begin: "2024-07-01T00:00:00-0700",
           period_end: "2024-10-01T00:00:00-0700"

      expect(last_response).to have_status(200)
      expect(v.refresh).to have_attributes(external_name: "test")
    end

    it "can update the mobility adapter" do
      v = Suma::Fixtures.vendor_service.create

      post "/v1/vendor_services/#{v.id}", mobility_adapter_setting: "deep_linking_suma_receipts"

      expect(last_response).to have_status(200)
      expect(v.refresh).to have_attributes(mobility_adapter_setting: "deep_linking_suma_receipts")
    end

    it "adds and removes categories" do
      v = Suma::Fixtures.vendor_service.create
      cat1 = Suma::Fixtures.vendor_service_category.create
      cat2 = Suma::Fixtures.vendor_service_category.create

      post "/v1/vendor_services/#{v.id}", categories: {0 => {id: cat1.id}, 1 => {id: cat2.id}}

      expect(last_response).to have_status(200)
      expect(v.refresh.categories).to have_same_ids_as(cat1, cat2)

      post "/v1/vendor_services/#{v.id}", categories: {0 => {id: cat2.id}}

      expect(last_response).to have_status(200)
      expect(v.refresh.categories).to have_same_ids_as(cat2)
    end
  end

  describe "GET /v1/vendor_services/mobility_adapter_options" do
    it "returns options" do
      get "/v1/vendor_services/mobility_adapter_options"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: include({name: "No Adapter/Non-Mobility", value: "no_adapter"}),
      )
    end
  end
end
