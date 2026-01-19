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
  end
end
