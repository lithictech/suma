# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::EligibilityRequirements < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedEligibilityRequirement < EligibilityRequirementEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :created_by, with: AuditMemberEntity
    expose :programs, with: ProgramEntity
    expose :payment_triggers, with: PaymentTriggerEntity
    expose :expression, &self.delegate_to(:expression, :serialize)
    expose :expression_tokens, &self.delegate_to(:expression, :tokenize)
  end

  class EditorTokenOptionEntity < BaseEntity
    expose :id
    expose :value
    expose :label
    expose :type
  end

  class EditorSettingsKeyMapping < BaseEntity
    expose :key
    expose :token, with: EditorTokenOptionEntity
  end

  class EditorSettingsEntity < BaseEntity
    expose :parens, with: EditorTokenOptionEntity
    expose :operators, with: EditorTokenOptionEntity
    expose :attributes, with: EditorTokenOptionEntity
    expose :key_mappings, with: EditorSettingsKeyMapping
  end

  class EditorDetokenizationWarningEntity < BaseEntity
    expose :index
    expose :message
    expose :value
    expose :string, &self.delegate_to(:to_s)
  end

  class EditorExpressionEvaluationEntity < BaseEntity
    expose :member, with: Suma::AdminAPI::Entities::MemberEntity
    expose :assignments
    expose :expressions
  end

  resource :eligibility_requirements do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Eligibility::Requirement,
      EligibilityRequirementEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Eligibility::Requirement,
      EligibilityRequirementEntity,
      around: lambda do |_rt, m, &b|
        b.call
        m.all_resources.each { |r| r.audit_activity("addeligibility", action: m) }
      end,
    ) do
      params do
        optional :programs, type: Array[JSON] do
          use :model_with_id
        end
        optional :payment_triggers, type: Array[JSON] do
          use :model_with_id
        end
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Eligibility::Requirement,
      DetailedEligibilityRequirement,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Eligibility::Requirement,
      DetailedEligibilityRequirement,
      around: lambda do |rt, m, &block|
        expr = rt.params.delete(:expression)
        block.call
        if expr
          m.replace_expression(expr.deep_symbolize_keys)
          m.all_resources.each { |r| r.audit_activity("changedeligibility", action: m.cached_expression_string) }
        end
      end,
    ) do
      params do
        optional :programs, type: Array[JSON] do
          use :model_with_id
        end
        optional :payment_triggers, type: Array[JSON] do
          use :model_with_id
        end
        optional :expression, type: JSON
      end
    end

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::Eligibility::Requirement,
      DetailedEligibilityRequirement,
      around: lambda do |_rt, m, &b|
        m.all_resources.each { |r| r.audit_activity("removedeligibility", action: m) }
        b.call
      end,
    )

    resource :editor do
      get :settings do
        check_admin_role_access!(:read, Suma::Eligibility::Requirement)
        attributes = Suma::Eligibility::Attribute.all.
          sort_by { |a| a.fqn_label.reverse }.
          map do |a|
          Suma::Eligibility::Expression::Tokenizer::Token.from_attribute(a)
        end
        settings = {
          parens: Suma::Eligibility::Expression::Tokenizer::PAREN_TOKENS,
          operators: Suma::Eligibility::Expression::Tokenizer::OPERATOR_TOKENS,
          attributes:,
          key_mappings: [
            {key: "(", token: Suma::Eligibility::Expression::Tokenizer::TOK_PAREN_OPEN},
            {key: ")", token: Suma::Eligibility::Expression::Tokenizer::TOK_PAREN_CLOSE},
            {key: "&", token: Suma::Eligibility::Expression::Tokenizer::TOK_OP_AND},
            {key: "|", token: Suma::Eligibility::Expression::Tokenizer::TOK_OP_OR},
            {key: "!", token: Suma::Eligibility::Expression::Tokenizer::TOK_OP_NOT},
          ],
        }

        present settings, with: EditorSettingsEntity
      end

      params do
        requires :tokens, type: Array[JSON] do
          requires :id
          requires :value
          requires :label
          requires :type, type: Symbol, values: [:operator, :paren, :variable]
        end
      end
      post :detokenize do
        check_admin_role_access!(:read, Suma::Eligibility::Requirement)
        dparams = declared(params)
        tokens = dparams[:tokens].map do |h|
          Suma::Eligibility::Expression::Tokenizer::Token.new(**h.deep_symbolize_keys)
        end
        r = Suma::Eligibility::Expression::Tokenizer.detokenize(tokens)
        status 200
        present r.to_h
      end

      params do
        requires :requirement_id, type: Integer
        requires :serialized_expression, type: JSON
        optional :member_id, type: Integer
      end
      post :evaluate_expression do
        check_admin_role_access!(:read, Suma::Eligibility::Requirement)
        check_admin_role_access!(:read, Suma::Member)
        member = if (member_id = params[:member_id])
                   Suma::Member[member_id] or forbidden!("no member with that ID")
                 else
                   current_member
                 end

        (req = Suma::Eligibility::Requirement[params[:requirement_id]]) or forbidden!("no requirement with that id")
        tbls = req.db.transaction(rollback: :always) do
          req.replace_expression(params[:serialized_expression].deep_symbolize_keys)
          Suma::Eligibility::Evaluation.evaluate(member, [req]).to_structured_tables
        end
        tbls.transform_values! { |a| a.map(&:to_h) }
        tbls[:member] = member
        status 200
        present tbls, with: EditorExpressionEvaluationEntity
      end
    end
  end
end
