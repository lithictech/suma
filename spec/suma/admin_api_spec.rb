# frozen_string_literal: true

require "rack/test"

require "suma/admin_api"

class Suma::AdminAPI::TestV1API < Suma::AdminAPI::V1
  route_setting :skip_role_check, true
  get :noop do
    present({})
  end
  route_setting :skip_role_check, true
  get :unique_constraint do
    Suma::Fixtures.vendor_service_category.create(slug: "x")
    Suma::Fixtures.vendor_service_category.create(slug: "x")
  end
  route_setting :skip_role_check, true
  get :validation do
    Suma::Fixtures.member.create(phone: nil)
  end
  route_setting :skip_role_check, true
  get :content_type do
    Suma::UploadedFile.create_with_blob(bytes: Suma::SpecHelpers::PNG_1X1_BYTES, content_type: "image/jpeg")
  end

  get :missing_role_check do
  end
  get :role_check do
    check_admin_role_access!(:read, :admin_access)
  end

  get :invalid_precond do
    raise Suma::InvalidPrecondition, "hello"
  end

  class ChildEntity < Suma::Service::Entities::Base
    expose :id
  end

  class ModelEntity < Suma::AdminAPI::Entities::BaseModelEntity
    model Suma::Vendor
    expose :name
    expose_related :products, with: ChildEntity
    expose_related :products, as: :children, with: ChildEntity
  end

  route_setting :skip_role_check, true
  resource :model_with_related do
    route_param :id do
      get do
        vendor = Suma::Vendor.find!(id: params[:id])
        present vendor, with: ModelEntity
      end

      Suma::AdminAPI::CommonEndpoints.related(
        self,
        Suma::Vendor,
        Suma::Commerce::Product,
        ChildEntity,
        :products,
      )
    end
  end
end

RSpec.describe Suma::AdminAPI, :db do
  include Rack::Test::Methods

  let(:admin) { Suma::Fixtures.member.admin.create }

  describe described_class::V1 do
    let(:app) { Suma::AdminAPI::TestV1API.build_app }

    before(:each) do
      login_as admin
    end

    it "converts unique constraint violations to 400s" do
      get "/v1/unique_constraint"

      expect(last_response).to have_status(400)
      expect(last_response.body).to include("vendor_service_categories_slug_key")
    end

    it "converts validation failures to 400s" do
      get "/v1/validation"

      expect(last_response).to have_status(400)
      expect(last_response.body).to include("phone is not present")
    end

    it "converts mismatched content types to 400s" do
      get "/v1/content_type"

      expect(last_response).to have_status(400)
      expect(last_response.body).to include("'image/jpeg' does not match derived 'image/png'")
    end

    it "configures sentry" do
      scope = Class.new do
        attr_accessor :tags

        def set_tags(tags)
          @tags = tags
        end

        def respond_to_missing?(*) = true
        def method_missing(*); end
      end
      sc = scope.new
      expect(Sentry).to receive(:configure_scope) do |&block|
        block.call(sc)
      end.at_least(:once)

      get "/v1/noop"

      expect(last_response).to have_status(200)
      expect(sc.tags).to eq(application: "admin-api")
    end

    it "errors if check_role_access is not called and :skip_role_check is not set" do
      get "/v1/missing_role_check"

      expect(last_response).to have_status(500)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "check_admin_role_access! was not called"))
    end

    it "does not fail if check_admin_role_access is called" do
      get "/v1/role_check"

      expect(last_response).to have_status(200)
    end

    it "does not fail if check_admin_role_access is called" do
      get "/v1/invalid_precond"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "Hello"))
    end

    describe "related lists", reset_configuration: Suma::Service do
      before(:each) do
        Suma::Service.related_list_size = 4
      end

      let(:vendor) do
        vendor = Suma::Fixtures.vendor.create(name: "foo")
        Array.new(5) { Suma::Fixtures.product.create(vendor:) }
        vendor
      end

      it "is exposed on the entity" do
        get "/v1/model_with_related/#{vendor.id}"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.
          that_includes(
            name: "foo",
            products: include(
              current_page: 1,
              page_count: 2,
              total_count: 5,
              has_more: true,
              url: "/v1/model_with_related/#{vendor.id}/products",
              items: have_length(4),
            ),
            children: include(items: have_length(4)),
          )
      end

      it "can be expanded" do
        get "/v1/model_with_related/#{vendor.id}", expand: ["products"]

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.
          that_includes(
            products: include(
              current_page: 1,
              page_count: 1,
              total_count: 5,
              has_more: false,
              items: have_length(5),
            ),
          )
      end

      it "can expose a paginated list endpoint" do
        get "/v1/model_with_related/#{vendor.id}/products", page: 2, per_page: 2

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.
          that_includes(
            current_page: 2,
            page_count: 3,
            total_count: 5,
            has_more: true,
            url: "/v1/model_with_related/#{vendor.id}/products",
            items: have_length(2),
          )
      end
    end
  end

  describe "entities" do
    describe "entity" do
      entities = ObjectSpace.each_object(Class).
        select { |c| (c < Suma::AdminAPI::Entities::BaseEntity) && c.include?(Suma::AdminAPI::Entities::AutoExposeBase) }

      entities.each do |entity_class|
        describe entity_class.name do
          it "expose a label" do
            exposed = (entity_class.root_exposures.map(&:attribute) | entity_class.root_exposures.map(&:key)).sort
            expect(exposed).to include(:label), "#{entity_class} is missing a :label exposure"
          end
        end
      end
    end
  end
end
