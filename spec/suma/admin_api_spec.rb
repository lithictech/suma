# frozen_string_literal: true

require "rack/test"

require "suma/admin_api"

class Suma::AdminAPI::TestV1API < Suma::AdminAPI::V1
  get :noop do
    present({})
  end
  get :unique_constraint do
    Suma::Fixtures.vendor_service_category.create(slug: "x")
    Suma::Fixtures.vendor_service_category.create(slug: "x")
  end
  get :validation do
    Suma::Fixtures.member.create(phone: nil)
  end
  get :content_type do
    Suma::UploadedFile.create_with_blob(bytes: Suma::SpecHelpers::PNG_1X1_BYTES, content_type: "image/jpeg")
  end
end

RSpec.describe Suma::AdminAPI::V1, :db do
  include Rack::Test::Methods

  let(:app) { Suma::AdminAPI::TestV1API.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

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
end
