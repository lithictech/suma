# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::PaymentTriggers < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class PaymentTriggerEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :label
    expose :active_during_begin
    expose :active_during_end
  end

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
    expose :match_multiplier
    expose :maximum_cumulative_subsidy_cents
    expose :memo, with: TranslatedTextEntity
    expose :originating_ledger, with: SimpleLedgerEntity
    expose :receiving_ledger_name
    expose :receiving_ledger_contribution_text, with: TranslatedTextEntity
    expose :executions, with: PaymentTriggerExecutionEntity
  end

  resource :payment_triggers do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Payment::Trigger,
      PaymentTriggerEntity,
      translation_search_params: [:memo],
    )

    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Payment::Trigger, DetailedPaymentTriggerEntity)

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
        requires :originating_ledger_id, type: Integer
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
        optional :originating_ledger_id, type: Integer
        optional :receiving_ledger_name, type: String
        optional(:receiving_ledger_contribution_text, type: JSON) { use :translated_text }
      end
    end

    params do
      requires :member_id, type: Integer
      requires :amount_cents, type: Integer
      requires :as_of, type: Time
    end
    post :plan do
    end
  end
end
