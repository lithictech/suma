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
        return [Suma::Fixtures.eligibility_requirement.attribute("zzz").create]
      end

      def make_non_matching_items
        return [Suma::Fixtures.eligibility_requirement.attribute("wibble").create]
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
        id: requirement.id, resources: [],
      )
    end

    it "403s if the item does not exist" do
      get "/v1/eligibility_requirements/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/eligibility_requirements/:id" do
    it "updates the expression" do
      attr1 = Suma::Fixtures.eligibility_attribute.create(name: "attr1")
      attr2 = Suma::Fixtures.eligibility_attribute.create(name: "attr2")

      ex = {
        left: {
          left: {
            left: {
              left: {attr: attr1.id},
              right: {attr: attr2.id},
              op: "AND",
            },
          },
        },
        op: "OR",
        right: {attr: attr2.id},
      }
      r = Suma::Fixtures.eligibility_requirement.create

      post "/v1/eligibility_requirements/#{r.id}", expression: ex

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: r.id)
      expect(r.refresh.cached_expression_string).to eq("(('attr1' AND 'attr2') OR 'attr2')")
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

  describe "GET /v1/eligibility_requirements/editor/settings" do
    it "returns settings" do
      a1 = Suma::Fixtures.eligibility_attribute.create(name: "A1")
      a2 = Suma::Fixtures.eligibility_attribute.create(name: "A2", parent: a1)

      get "/v1/eligibility_requirements/editor/settings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          operators: include(include(id: "AND", value: "AND")),
          attributes: [
            include(id: a1.id, label: "A1", value: "A1"),
            include(id: a2.id, label: "A2", value: "A2.A1"),
          ],
          key_mappings: include(include(key: "(", token: include(id: "("))),
        )
    end
  end

  describe "POST /v1/eligibility_requirements/editor/detokenize" do
    it "detokenizes and returns the result" do
      tizer = Suma::Eligibility::Expression::Tokenizer

      post "/v1/eligibility_requirements/editor/detokenize", tokens: [
        tizer::Token.new(id: 1, value: "x", label: "x", type: tizer::VARIABLE).to_h,
        tizer::Token.constant("AND", tizer::OPERATOR).to_h,
        tizer::Token.new(id: 2, value: "y", label: "y", type: tizer::VARIABLE).to_h,
      ]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          node: {
            left: {
              attr: 1,
              name: "x",
              fqn: "x",
            },
            op: "AND",
            right: {
              attr: 2,
              name: "y",
              fqn: "y",
            },
          },
          error_index: nil,
          error_value: nil,
          error_reason: nil,
          error_message: nil,
        )
    end

    it "handles invalid expressions" do
      tizer = Suma::Eligibility::Expression::Tokenizer

      post "/v1/eligibility_requirements/editor/detokenize", tokens: [
        tizer::Token.new(id: 1, value: "x", label: "x", type: tizer::VARIABLE).to_h,
        tizer::Token.constant("AND", tizer::OPERATOR).to_h,
      ]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          node: nil,
          error_index: 1,
          error_value: "AND",
          error_reason: "unexpected end of input",
          error_message: "unexpected end of input: (1) AND",
        )
    end
  end

  describe "POST /v1/eligibility_requirements/editor/evaluate_expression" do
    it "evaluates the serialized expression and rolls back the changes" do
      member = Suma::Fixtures.member.create
      attr = Suma::Fixtures.eligibility_attribute.create
      Suma::Fixtures.eligibility_assignment.create(member:, attribute: attr)

      req = Suma::Fixtures.eligibility_requirement.create
      orig_expr = req.expression

      post "/v1/eligibility_requirements/editor/evaluate_expression",
           member_id: member.id,
           requirement_id: req.id,
           serialized_expression: {attr: attr.id}

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          assignments: contain_exactly(include(label: attr.fqn_label, source_type: "member")),
          expressions: contain_exactly(include(formula: "'#{attr.name}'", passed: true)),
        )

      expect(req.refresh.expression).to be === orig_expr
    end

    it "defaults to the current impersonated user" do
      member = Suma::Fixtures.member.create
      attr = Suma::Fixtures.eligibility_attribute.create
      Suma::Fixtures.eligibility_assignment.create(member:, attribute: attr)

      impersonate(admin:, target: member)

      req = Suma::Fixtures.eligibility_requirement.create

      post "/v1/eligibility_requirements/editor/evaluate_expression",
           requirement_id: req.id,
           serialized_expression: {attr: attr.id}

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          member: include(id: member.id),
          assignments: contain_exactly(
            include(source_type: "member", sources: contain_exactly(include(id: member.id))),
          ),
          expressions: contain_exactly(include(formula: "'#{attr.name}'", passed: true)),
        )
    end
  end
end
