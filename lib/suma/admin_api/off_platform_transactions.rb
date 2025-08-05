# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::OffPlatformTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedOffPlatformTransactionEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :funding_transaction, with: FundingTransactionEntity
    expose :payout_transaction, with: PayoutTransactionEntity
    expose :type
    expose :amount, with: MoneyEntity, &self.delegate_to(:transaction, :amount)
    expose :transacted_at
    expose :note
    expose :check_or_transaction_number
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
        tx.audit_one_off(event, messages)
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
      if params[:type] == :funding
        model_cls = Suma::Payment::FundingTransaction
        startparams = {originating_ip: request.ip}
        process_event = :collect_funds
      else
        model_cls = Suma::Payment::PayoutTransaction
        startparams = {}
        process_event = :send_funds
      end
      check_admin_role_access!(:write, model_cls)
      check_or_transaction_number = params[:check_or_transaction_number]
      check_or_transaction_number = nil if check_or_transaction_number.blank?
      strategy = model_cls.db.transaction do
        strategy = Suma::Payment::OffPlatformStrategy.create(
          transacted_at: params[:transacted_at],
          note: params[:note],
          check_or_transaction_number:,
          created_by: admin_member,
        )
        tx = model_cls.start_new(
          Suma::Payment::Account.lookup_platform_account,
          amount: params[:amount],
          strategy:,
          **startparams,
        )
        audit_transaction_values(strategy, "created")
        tx.must_process(process_event)
        strategy
      end
      created_resource_headers(strategy.transaction.id, strategy.transaction.admin_link)
      status 200
      present strategy, with: DetailedOffPlatformTransactionEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup(access)
          (strat = Suma::Payment::OffPlatformStrategy[params[:id]]) or forbidden!
          tx = strat.transaction
          check_admin_role_access!(access, tx.class)
          return strat
        end
      end

      get do
        strat = lookup(:read)
        status 200
        present strat, with: DetailedOffPlatformTransactionEntity
      end

      params do
        optional(:amount, allow_blank: false, type: JSON) { use :money }
        optional :transacted_at, type: Time
        optional :note, type: String, allow_blank: false
        optional :check_or_transaction_number, type: String
      end
      post do
        strat = lookup(:write)
        tx = strat.transaction
        strat.db.transaction do
          tx.amount = params[:amount] if params.key?(:amount)
          [:transacted_at, :note, :check_or_transaction_number].each do |k|
            strat[k] = params[k] if params.key?(k)
          end
          strat.save_changes
          tx.save_changes
          audit_transaction_values(strat, "updated")
        end
        created_resource_headers(tx.id, tx.admin_link)
        status 200
        present strat, with: DetailedOffPlatformTransactionEntity
      end
    end
  end
end
