# frozen_string_literal: true

require "suma/api"

class Suma::API::PaymentInstruments < Suma::API::V1
  include Suma::API::Entities

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
        add_current_member_header
        status 200
        present(
          ba,
          with: MutationPaymentInstrumentEntity,
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
        me.stripe.ensure_registered_as_customer
        card = me.db.transaction do
          # token fingerprint is not passed through params
          # for security reasons, fetch it with stripe API instead
          tok_fingerprint = Stripe::Token.retrieve(params[:token][:id]).card.fingerprint
          existing_card = me.legal_entity.cards_dataset.usable.all.find { |c| c.fingerprint === tok_fingerprint }
          if existing_card
            existing_card
          else
            stripe_card = me.stripe.register_card_for_charges(params[:token][:id])
            Suma::Payment::Card.create(
              legal_entity: me.legal_entity,
              stripe_json: stripe_card.to_json,
            )
          end
        end
        add_current_member_header
        status 200
        present(
          card,
          with: MutationPaymentInstrumentEntity,
          all_payment_instruments: me.usable_payment_instruments,
        )
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
