# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::PaymentOffPlatform < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :payment_off_platform do
    helpers do
      def type_specific_fields
        if params[:type] == :funding
          return [
            Suma::Payment::FundingTransaction,
            FundingTransactionEntity,
            {originating_ip: request.ip},
            :collect_funds,
          ]
        end
        return [
          Suma::Payment::PayoutTransaction,
          PayoutTransactionEntity,
          {},
          :send_funds,
        ]
      end

      def audit_transaction_values(x, event)
        messages = []
        messages << "amount=#{x.amount}" if params.key?(:amount)
        [:transacted_at, :note, :check_or_transaction_number].each do |k|
          next unless params.key?(k)
          messages << "#{k}=#{x.strategy.send(k)}"
        end
        x.audit_one_off(event, messages)
      end
    end

    desc "Create a funding or payout transaction using the off platform strategy."
    params do
      requires :type, type: Symbol, values: [:funding, :payout]
      requires(:amount, allow_blank: false, type: JSON) { use :money }
      requires :transacted_at, type: Time
      requires :note, type: String, allow_blank: false
      optional :check_or_transaction_number, type: String
    end
    post :create do
      model_cls, entity, startparams, process_event = type_specific_fields
      check_admin_role_access!(:write, model_cls)
      check_or_transaction_number = params[:check_or_transaction_number]
      check_or_transaction_number = nil if check_or_transaction_number.blank?
      tx = model_cls.db.transaction do
        strategy = Suma::Payment::OffPlatformStrategy.create(
          transacted_at: params[:transacted_at],
          note: params[:note],
          check_or_transaction_number:,
        )
        tx = model_cls.start_new(
          Suma::Payment::Account.lookup_platform_account,
          amount: params[:amount],
          strategy:,
          **startparams,
        )
        audit_transaction_values(tx, "created")
        tx.must_process(process_event)
        tx
      end
      created_resource_headers(tx.id, tx.admin_link)
      status 200
      present tx, with: entity
    end

    params do
      requires :type, type: Symbol, values: [:funding, :payout]
      requires :id, type: Integer, allow_blank: false
      optional(:amount, allow_blank: false, type: JSON) { use :money }
      optional :transacted_at, type: Time
      optional :note, type: String, allow_blank: false
      optional :check_or_transaction_number, type: String
    end
    post :update do
      model_cls, entity, _ = type_specific_fields
      check_admin_role_access!(:write, model_cls)
      (fx = model_cls[params[:id]]) or forbidden!
      adminerror!(403, "transaction does not use an off platform strategy") unless fx.off_platform_strategy_id
      fx.db.transaction do
        fx.amount = params[:amount] if params.key?(:amount)
        [:transacted_at, :note, :check_or_transaction_number].each do |k|
          fx.strategy[k] = params[k] if params.key?(k)
        end
        fx.save_changes
        fx.strategy.save_changes
        audit_transaction_values(fx, "updated")
      end
      status 200
      present fx, with: entity
    end
  end
end
