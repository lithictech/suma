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
        # See https://devdocs.helcim.com/docs/response-fields#post-response-sample
        requires :xml, type: String
      end
      post :create_helcim do
        me = current_member
        helcim_json = Hash.from_xml(params[:xml]).fetch("message")
        if helcim_json.fetch("response") != "1"
          self.logger.warn("helcim_error_response", helcim_xml: params["xml"])
          merror!(402, helcim_json.fetch("responseMessage") || "Helcim Error", code: "invalid_card")
        end
        card = Suma::Payment::Card.create(
          legal_entity: me.legal_entity,
          helcim_json:,
        )
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
