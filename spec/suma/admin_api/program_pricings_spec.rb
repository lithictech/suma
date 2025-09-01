# frozen_string_literal: true

require "suma/admin_api/program_pricings"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::ProgramPricings, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "POST /v1/program_pricings/create" do
    it "creates a model" do
      program = Suma::Fixtures.program.create
      vendor_service = Suma::Fixtures.vendor_service.create
      rate = Suma::Fixtures.vendor_service_rate.create
      post "/v1/program_pricings/create",
           program: {id: program.id},
           vendor_service: {id: vendor_service.id},
           vendor_service_rate: {id: rate.id}

      expect(last_response).to have_status(200)
      expect(Suma::Program::Pricing.all).to have_length(1)
      expect(last_response).to have_json_body.that_includes(
        program: include(id: program.id),
      )
      expect(program.refresh.audit_activities).to contain_exactly(have_attributes(message_name: "addpricing"))
    end
  end

  describe "GET /v1/program_pricings/:id" do
    it "returns the model" do
      pricing = Suma::Fixtures.program_pricing.create

      get "/v1/program_pricings/#{pricing.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: pricing.id)
    end
  end

  describe "POST /v1/program_pricings/:id" do
    it "updates the model" do
      pricing = Suma::Fixtures.program_pricing.create
      rate2 = Suma::Fixtures.vendor_service_rate.create

      post "/v1/program_pricings/#{pricing.id}", vendor_service_rate: {id: rate2.id}

      expect(last_response).to have_status(200)
      expect(pricing.refresh).to have_attributes(vendor_service_rate: be === rate2)
      expect(pricing.program.audit_activities).to contain_exactly(have_attributes(message_name: "changepricing"))
    end
  end

  describe "POST /v1/program_pricings/:id/destroy" do
    it "destroys the resource" do
      m = Suma::Fixtures.program_pricing.create

      post "/v1/program_pricings/#{m.id}/destroy"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: m.id)
      expect(m.program.audit_activities).to contain_exactly(have_attributes(message_name: "deletepricing"))
      expect(m).to be_destroyed
    end
  end
end
