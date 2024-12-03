# frozen_string_literal: true

require "suma/admin_api/program_enrollments"

RSpec.describe Suma::AdminAPI::ProgramEnrollments, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/program_enrollments" do
    it "returns all programs enrollments" do
      objs = Array.new(2) { Suma::Fixtures.program_enrollment.create }

      get "/v1/program_enrollments"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end
  end

  describe "POST /v1/program_enrollments/create" do
    it "creates the program enrollment for member" do
      member = Suma::Fixtures.member.create
      program = Suma::Fixtures.program.create

      post "/v1/program_enrollments/create", program: {id: program.id}, member: {id: member.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Program::Enrollment.all).to have_length(1)
    end

    it "creates the program enrollment for organization" do
      organization = Suma::Fixtures.organization.create
      program = Suma::Fixtures.program.create

      post "/v1/program_enrollments/create", program: {id: program.id}, organization: {id: organization.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Program::Enrollment.all).to have_length(1)
    end

    it "creates the program enrollment for role" do
      role = Suma::Role.create(name: "test")
      program = Suma::Fixtures.program.create

      post "/v1/program_enrollments/create", program: {id: program.id}, role: {id: role.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Program::Enrollment.all).to have_length(1)
    end
  end

  describe "GET /v1/program_enrollments/:id" do
    it "returns the program enrollment" do
      enrollment = Suma::Fixtures.program_enrollment.create

      get "/v1/program_enrollments/#{enrollment.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: enrollment.id,
        enrollee: include(id: enrollment.member.id),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/program_enrollments/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/program_enrollments/:id" do
    it "updates a program enrollment" do
      enrollment = Suma::Fixtures.program_enrollment.unapproved.create

      post "/v1/program_enrollments/#{enrollment.id}", approved: true, approved_by: {id: admin.id}

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        approved: true,
        approved_by: include(id: admin.id),
        unenrolled: false,
        unenrolled_by: be_nil,
      )
    end
  end
end
