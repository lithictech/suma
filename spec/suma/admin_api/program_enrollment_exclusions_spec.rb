# frozen_string_literal: true

require "suma/admin_api/program_enrollment_exclusions"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::ProgramEnrollmentExclusions, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "POST /v1/program_enrollment_exclusions/create" do
    it "creates the model" do
      member = Suma::Fixtures.member.create
      program = Suma::Fixtures.program.create

      post "/v1/program_enrollment_exclusions/create", program: {id: program.id}, member: {id: member.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Program::EnrollmentExclusion.all).to have_length(1)
      expect(program.audit_activities).to contain_exactly(have_attributes(message_name: "addexclusion"))
    end
  end

  describe "GET /v1/program_enrollment_exclusions/:id" do
    it "returns the model" do
      m = Suma::Fixtures.program_enrollment_exclusion.create

      get "/v1/program_enrollment_exclusions/#{m.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: m.id)
    end
  end

  describe "POST /v1/program_enrollment_exclusions/:id/destroy" do
    it "destroys the resource" do
      m = Suma::Fixtures.program_enrollment_exclusion.create

      post "/v1/program_enrollment_exclusions/#{m.id}/destroy"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: m.id)
      expect(last_response.headers).to include("Created-Resource-Id" => m.program.id.to_s)
      expect(m.program.audit_activities).to contain_exactly(have_attributes(message_name: "removeexclusion"))
      expect(m).to be_destroyed
    end
  end
end
