# frozen_string_literal: true

require "suma/api"

class Suma::API::PaymentInstruments < Suma::API::V1
  include Suma::API::Entities

  resource :payment_instruments do
    get do
      status 200
      present_collection current_member.usable_payment_instruments, with: PaymentInstrumentEntity
    end
    route_param :id, type: Integer do
      params do
        requires :payment_method_type, type: String, values: ["bank_account", "card"]
      end
      get do
        instrument_ds = case params[:payment_method_type]
            when "bank_account"
              Suma::Payment::BankAccount.dataset
            when "card"
              Suma::Payment::Card.dataset
          end
        (instrument = instrument_ds[params[:id]]) or forbidden!
        present instrument, with: PaymentInstrumentEntity
      end
    end

    resource :bank_accounts do
      params do
        requires :name, type: String, allow_blank: false
        requires :routing_number, type: String, allow_blank: false
        requires :account_number, type: String, allow_blank: false
        requires :account_type, type: String, values: ["checking", "savings"]
      end
      post :create do
        c = current_member
        merror!(402, "Bank account creation not supported", code: "forbidden") unless
          Suma::Payment.method_supported?("bank_account")

        account_number = params.delete(:account_number)
        routing_number = params.delete(:routing_number)
        identity = Suma::Payment::BankAccount.identity(c.legal_entity_id, routing_number, account_number)
        ba = c.legal_entity.bank_accounts_dataset[identity:]
        if ba.nil?
          ba = Suma::Payment::BankAccount.new(legal_entity: c.legal_entity, account_number:, routing_number:)
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
        status 200
        present(ba, with: PaymentInstrumentEntity)
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
            with: MutationPaymentInstrumentEntity,
            all_payment_instruments: current_member.usable_payment_instruments,
          )
        end
      end
    end

    resource :cards do
      params do
        # See https://stripe.com/docs/api/tokens/object
        requires :token, type: JSON do
          requires :id, type: String
        end
      end
      post :create_stripe do
        me = current_member
        merror!(402, "Card creation not supported", code: "forbidden") unless
          Suma::Payment.method_supported?("card")
        card = me.db.transaction do
          me.stripe.ensure_registered_as_customer
          stripe_card = me.stripe.register_card_for_charges(params[:token][:id])
          Suma::Payment::Card.create(
            legal_entity: me.legal_entity,
            stripe_json: stripe_card.to_json,
          )
        end
        status 200
        present(card, with: PaymentInstrumentEntity)
      end
      route_param :id, type: Integer do
        helpers do
          def lookup
            c = current_member
            card = c.legal_entity.cards_dataset.usable[params[:id]]
            merror!(403, "No card with that id", code: "resource_not_found") if card.nil?
            return card
          end
        end
        delete do
          card = lookup
          card.stripe_card.delete
          card.soft_delete
          present(
            card,
            with: MutationPaymentInstrumentEntity,
            all_payment_instruments: current_member.usable_payment_instruments,
          )
        end
      end
    end
  end

  class MutationPaymentInstrumentEntity < PaymentInstrumentEntity
    include Suma::API::Entities
    expose :all_payment_instruments, with: PaymentInstrumentEntity do |_inst, opts|
      opts.fetch(:all_payment_instruments)
    end
  end
end
