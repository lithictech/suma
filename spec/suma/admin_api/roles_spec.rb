# frozen_string_literal: true

require "suma/admin_api/roles"

RSpec.describe Suma::AdminAPI::Roles, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.customer.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/roles" do
    it "returns all roles" do
      c = Suma::Role.create(name: "c")
      d = Suma::Role.create(name: "d")
      b = Suma::Role.create(name: "b")

      get "/v1/roles"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(Suma::Role.admin_role, b, c, d).ordered)
    end
  end
end
