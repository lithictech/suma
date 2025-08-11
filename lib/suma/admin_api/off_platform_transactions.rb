# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::OffPlatformTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedOffPlatformTransactionEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    include AutoExposeDetail
    expose :funding_transaction, with: FundingTransactionEntity
    expose :payout_transaction, with: PayoutTransactionEntity
    expose :transaction_admin_link, &self.delegate_to(:transaction, :admin_link)
    expose :type
    expose :amount, with: MoneyEntity, &self.delegate_to(:transaction, :amount)
    expose :transacted_at
    expose :note
    expose :check_or_transaction_number
    expose :organization, with: OrganizationEntity
    expose :vendor, with: VendorEntity
  end

  resource :off_platform_transactions do
    helpers do
      def audit_transaction_values(strat, event)
        tx = strat.transaction
        messages = []
        messages << "amount=#{tx.amount}" if params.key?(:amount)
        [:transacted_at, :note, :check_or_transaction_number].each do |k|
          next unless params.key?(k)
          messages << "#{k}=#{strat.send(k)}"
        end
        [:vendor, :organization].each do |k|
          next unless params.key?(k)
          messages << "#{k}=#{strat.send(k).name}"
        end
        tx.audit_one_off(event, messages)
      end
    end

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Payment::OffPlatformStrategy,
      DetailedOffPlatformTransactionEntity,
      around: lambda do |rt, strategy, &block|
        rt.params[:created_by] = rt.admin_member
        if rt.params[:type] == :funding
          model_cls = Suma::Payment::FundingTransaction
          startparams = {originating_ip: rt.request.ip}
          process_event = :collect_funds
        else
          model_cls = Suma::Payment::PayoutTransaction
          startparams = {}
          process_event = :send_funds
        end
        block.call
        tx = model_cls.start_new(
          Suma::Payment::Account.lookup_platform_account,
          amount: rt.params[:amount],
          strategy:,
          **startparams,
        )
        rt.audit_transaction_values(strategy, "created")
        tx.must_process(process_event)
      end,
    ) do
      params do
        requires :type, type: Symbol, values: [:funding, :payout]
        requires(:amount, allow_blank: false, type: JSON) { use :money }
        requires :transacted_at, type: Time
        requires :note, type: String, allow_blank: false
        optional :check_or_transaction_number, type: String
        optional(:organization, type: JSON) { use :model_with_id }
        optional(:vendor, type: JSON) { use :model_with_id }
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Payment::OffPlatformStrategy,
      DetailedOffPlatformTransactionEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Payment::OffPlatformStrategy,
      DetailedOffPlatformTransactionEntity,
      around: lambda do |rt, strategy, &block|
        block.call
        strategy.transaction.update(amount: rt.params[:amount]) if rt.params.key?(:amount)
        rt.audit_transaction_values(strategy, "updated")
      end,
    ) do
      params do
        optional(:amount, allow_blank: false, type: JSON) { use :money }
        optional :transacted_at, type: Time
        optional :note, type: String, allow_blank: false
        optional :check_or_transaction_number, type: String
        optional(:organization, type: JSON) { use :model_with_id }
        optional(:vendor, type: JSON) { use :model_with_id }
      end
    end
  end
end
