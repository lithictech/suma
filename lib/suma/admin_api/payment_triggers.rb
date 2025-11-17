# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::PaymentTriggers < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class PaymentTriggerExecutionEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :id
    expose :admin_link, &self.delegate_to(:book_transaction, :admin_link)
    expose :book_transaction_id
    expose :at, &self.delegate_to(:book_transaction, :created_at)
    expose :receiving_ledger, with: SimpleLedgerEntity, &self.delegate_to(:book_transaction, :receiving_ledger)
  end

  class DetailedPaymentTriggerEntity < PaymentTriggerEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :audit_activities, with: ActivityEntity
    expose :match_multiplier, &self.delegate_to(:match_multiplier, :to_f)
    expose :match_fraction, &self.delegate_to(:match_fraction, :to_f)
    expose :payer_fraction, &self.delegate_to(:payer_fraction, :to_f)
    expose :maximum_cumulative_subsidy_cents
    expose :memo, with: TranslatedTextEntity
    expose :originating_ledger, with: SimpleLedgerEntity
    expose :receiving_ledger_name
    expose :receiving_ledger_contribution_text, with: TranslatedTextEntity
    expose :executions, with: PaymentTriggerExecutionEntity
    expose :programs, with: ProgramEntity
  end

  resource :payment_triggers do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Payment::Trigger,
      PaymentTriggerEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Payment::Trigger,
      DetailedPaymentTriggerEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Payment::Trigger,
      DetailedPaymentTriggerEntity,
    ) do
      params do
        requires :label, type: String
        requires :active_during_begin, type: Time
        requires :active_during_end, type: Time
        requires :match_multiplier, type: Float
        requires :maximum_cumulative_subsidy_cents, type: Integer
        requires(:memo, type: JSON) { use :translated_text }
        requires(:originating_ledger, type: JSON) { use :model_with_id }
        requires :receiving_ledger_name, type: String
        requires(:receiving_ledger_contribution_text, type: JSON) { use :translated_text }
      end
    end

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Payment::Trigger,
      PaymentTriggerEntity,
    ) do
      params do
        optional :label, type: String
        optional :active_during_begin, type: Time
        optional :active_during_end, type: Time
        optional :match_multiplier, type: Float
        optional :maximum_cumulative_subsidy_cents, type: Integer
        optional(:memo, type: JSON) { use :translated_text }
        optional(:originating_ledger, type: JSON) { use :model_with_id }
        optional :receiving_ledger_name, type: String
        optional(:receiving_ledger_contribution_text, type: JSON) { use :translated_text }
      end
    end

    Suma::AdminAPI::CommonEndpoints.programs_update(
      self,
      Suma::Payment::Trigger,
      DetailedPaymentTriggerEntity,
    )

    route_param :id, type: Integer do
      params do
        requires :amount, type: Integer
        requires :unit, type: Symbol, values: [:day, :week, :month]
      end
      post :subdivide do
        check_admin_role_access!(:write, Suma::Payment::Trigger)
        (tr = Suma::Payment::Trigger[params[:id]]) or forbidden!
        tr.subdivide(amount: params[:amount], unit: params[:unit])
        created_resource_headers(tr.id, tr.admin_link)
        status 200
        present tr, with: DetailedPaymentTriggerEntity
      end
    end
  end
end
