# frozen_string_literal: true

require "suma/api"

class Suma::API::PaymentInstruments < Suma::API::V1
  resource :payment_instruments do
    resource :bank_accounts do
      params do
        requires :name, type: String, allow_blank: false
        requires :routing_number, type: String, allow_blank: false
        requires :account_number, type: String, allow_blank: false
        requires :account_type, type: String, values: ["checking", "savings"]
      end
      post :create do
        c = current_member
        account_number = params.delete(:account_number)
        routing_number = params.delete(:routing_number)
        ba = c.legal_entity.bank_accounts_dataset[account_number:, routing_number:]
        if ba.nil?
          ba = Suma::BankAccount.new(legal_entity: c.legal_entity, account_number:, routing_number:)
        elsif ba.soft_deleted?
          ba.soft_deleted_at = nil
        else
          merror!(409, "Bank account with that info already exists", code: "conflicting_bank_account")
        end
        if Suma::Payment.autoverify_account_numbers.any? { |ptrn| File.fnmatch(ptrn, account_number) }
          ba.verified_at ||= Time.now
        end
        set_declared(ba, params)
        save_or_error!(ba)
        add_current_member_header
        status 200
        present(
          ba,
          with: Suma::API::MutationPaymentInstrumentEntity,
          all_payment_instruments: c.usable_payment_instruments,
        )
      end

      route_param :id, type: Integer do
        helpers do
          def lookup
            c = current_member
            ba = c.legal_entity.bank_accounts_dataset.usable[params[:id]]
            merror!(403, "No bank account with that id", code: "resource_not_found") if ba.nil?
            return ba
          end
        end
        delete do
          ba = lookup
          ba.soft_delete
          present(
            ba,
            with: Suma::API::MutationPaymentInstrumentEntity,
            all_payment_instruments: current_member.usable_payment_instruments,
          )
        end
      end
    end
  end
end
