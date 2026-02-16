# frozen_string_literal: true

require "suma/admin_api/eligibility_requirements"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::EligibilityRequirements, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/eligibility_requirements" do
    it "returns all instances" do
      objs = Array.new(2) { Suma::Fixtures.eligibility_requirement.create }

      get "/v1/eligibility_requirements"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/eligibility_requirements" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.eligibility_requirement.create(member: Suma::Fixtures.member.named("zzz").create).create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.eligibility_requirement.create(member: Suma::Fixtures.member.named("wibble").create).create,
        ]
      end
    end
  end

  describe "POST /v1/eligibility_requirements/create" do
    it "creates the requirement for program" do
      program = Suma::Fixtures.program.create

      post "/v1/eligibility_requirements/create", program: {id: program.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Eligibility::Requirement.all).to have_length(1)
    end

    it "creates the requirement for payment trigger" do
      pt = Suma::Fixtures.payment_trigger.create

      post "/v1/eligibility_requirements/create", payment_trigger: {id: pt.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Eligibility::Requirement.all).to have_length(1)
    end
  end

  describe "GET /v1/eligibility_requirements/:id" do
    it "returns the requirement" do
      requirement = Suma::Fixtures.eligibility_requirement.create

      get "/v1/eligibility_requirements/#{requirement.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: requirement.id,
        resource: include(id: requirement.resource.id),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/eligibility_requirements/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/eligibility_requirements/:id" do
    it "updates the expression" do
      attr1 = Suma::Fixtures.eligibility_attribute.create(name: 'attr1')
      attr2 = Suma::Fixtures.eligibility_attribute.create(name: 'attr2')

      ex = {
        left: {
          left: {
            left: {
              left: attr1.id,
              right: attr2.id,
              operator: 'AND',
            }
          },
        },
        operator: 'OR',
        right: attr2.id,
      }
      r = Suma::Fixtures.eligibility_requirement.create

      post "/v1/eligibility_requirements/#{r.id}", expression: ex

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: r.id)
      expect(r.refresh.cached_expression_string).to eq('fff')
    end
  end


  describe "POST /v1/eligibility_requirements/:id/destroy" do
    it "destroys the resource" do
      m = Suma::Fixtures.eligibility_requirement.create

      post "/v1/eligibility_requirements/#{m.id}/destroy"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: m.id)
      expect(m).to be_destroyed
    end
  end
end
