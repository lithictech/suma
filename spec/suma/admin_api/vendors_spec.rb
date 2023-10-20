# frozen_string_literal: true

require "suma/admin_api/vendors"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Vendors, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "POST /v1/vendors/create" do
    it "creates a vendor" do
      post "/v1/vendors/create", name: "test"
      expect(last_response).to have_status(200)
      expect(Suma::Vendor.all.count).to equal(1)
    end

    it "403s if vendor exists" do
      v = Suma::Fixtures.vendor.create(name: "test")
      post "/v1/vendors/create", name: v.name
      expect(last_response).to have_status(403)
    end
  end
end
