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
    end

    desc "Create a funding or payout transaction using the off platform strategy."
    params do
      requires :type, type: Symbol, values: [:funding, :payout]
      requires(:amount, allow_blank: false, type: JSON) { use :money }
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
          note: params[:note],
          check_or_transaction_number:,
        )
        tx = model_cls.start_new(
          Suma::Payment::Account.lookup_platform_account,
          amount: params[:amount],
          strategy:,
          **startparams,
        )
        tx.audit_one_off(
          "created",
          [
            "note=#{tx.strategy.note}",
            "check_or_transaction_number=#{tx.strategy.check_or_transaction_number}",
          ],
        )
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
      optional :note, type: String, allow_blank: false
      optional :check_or_transaction_number, type: String
    end
    post :update do
      model_cls, entity, _ = type_specific_fields
      check_admin_role_access!(:write, model_cls)
      (fx = model_cls[params[:id]]) or forbidden!
      adminerror!(403, "transaction does not use an off platform strategy") unless fx.off_platform_strategy_id
      fx.db.transaction do
        messages = []
        [:note, :check_or_transaction_number].select { |k| params.key?(k) }.each do |f|
          messages << "#{f}=#{params[f]}"
          fx.strategy[f] = params[f]
        end
        fx.audit_one_off("updated", messages)
        fx.strategy.save_changes
      end
      status 200
      present fx, with: entity
    end
  end
end
