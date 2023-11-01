# frozen_string_literal: true

require "suma/admin_api/eligibility_constraints"

RSpec.describe Suma::AdminAPI::EligibilityConstraints, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "POST /v1/constraints/create" do
    it "creates the constraint" do
      post "/v1/constraints/create", name: "Test constraint"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Eligibility::Constraint.all).to have_length(1)
    end

    it "403s if constraint already exists exist" do
      ec = Suma::Fixtures.eligibility_constraint.create
      post "/v1/constraints/create", name: ec.name

      expect(last_response).to have_status(403)
    end
  end
end
