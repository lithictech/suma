# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"

module Suma::AdminAPI::Entities
  MoneyEntity = Suma::Service::Entities::Money
  LegalEntityEntity = Suma::Service::Entities::LegalEntityEntity
  TimeRangeEntity = Suma::Service::Entities::TimeRange
  AddressEntity = Suma::Service::Entities::Address

  class BaseEntity < Suma::Service::Entities::Base; end

  # Simple exposure of common fields that can be used for lists of entities.
  module AutoExposeBase
    def self.included(ctx)
      ctx.expose :id, if: ->(o) { o.respond_to?(:id) }
      ctx.expose :created_at, if: ->(o) { o.respond_to?(:created_at) }
      ctx.expose :soft_deleted_at, if: ->(o) { o.respond_to?(:soft_deleted_at) }
      ctx.expose :admin_link, if: ->(o, _) { o.respond_to?(:admin_link) }
    end
  end

  # More extensive exposure of common fields for when we show
  # detailed entities, or limited lists.
  module AutoExposeDetail
    def self.included?(ctx)
      ctx.expose :updated_at, if: ->(o) { o.respond_to?(:updated_at) }
      # Always expose an external links array when we mix this in
      ctx.expose :external_links do |inst|
        inst.respond_to?(:external_links) ? inst.external_links : []
      end
    end
  end

  class CurrentMemberEntity < Suma::Service::Entities::CurrentMember
    expose :impersonating, with: Suma::Service::Entities::CurrentMember do |_|
      self.impersonation.is? ? self.impersonation.current_member : nil
    end
  end

  class RoleEntity < BaseEntity
    expose :id
    expose :name
  end

  class PaymentInstrumentEntity < BaseEntity
    include AutoExposeBase
    expose :payment_method_type
    expose :legal_entity, with: LegalEntityEntity
    expose :institution
    expose :name
    expose :last4
    expose :simple_label
    expose :admin_label
  end

  class AuditMemberEntity < BaseEntity
    expose :id
    expose :email
    expose :name
    expose :admin_link
  end

  class AuditLogEntity < BaseEntity
    expose :id
    expose :at
    expose :event
    expose :to_state
    expose :from_state
    expose :reason
    expose :messages
    expose :actor, with: AuditMemberEntity
  end

  class MemberEntity < BaseEntity
    include AutoExposeBase
    expose :email
    expose :name
    expose :phone
    expose :timezone
  end

  class MessageDeliveryEntity < BaseEntity
    include AutoExposeBase
    expose :template
    expose :transport_type
    expose :transport_service
    expose :transport_message_id
    expose :sent_at
    expose :aborted_at
    expose :to
    expose :recipient, with: MemberEntity
  end

  class BankAccountEntity < PaymentInstrumentEntity
    include AutoExposeDetail
    expose :verified_at
    expose :routing_number
    expose :account_number
    expose :account_type
  end

  class VendorEntity < BaseEntity
    include AutoExposeBase
    expose :name
  end

  class VendorServiceCategoryEntity < BaseEntity
    expose :id
    expose :name
  end

  class ChargeEntity < BaseEntity
    include AutoExposeBase
    expose :opaque_id
    expose :undiscounted_subtotal, with: MoneyEntity
  end

  class SimpleLedgerEntity < BaseEntity
    include AutoExposeBase
    expose :name
    expose :account_name, &self.delegate_to(:account, :display_name)
    expose :admin_label
  end

  class SimplePaymentAccountEntity < BaseEntity
    include AutoExposeBase
    expose :display_name
  end

  class FundingTransactionEntity < BaseEntity
    include AutoExposeBase
    expose :status
    expose :amount, with: MoneyEntity
    expose :originating_payment_account, with: SimplePaymentAccountEntity
  end

  class BookTransactionEntity < BaseEntity
    include AutoExposeBase
    expose :apply_at
    expose :amount, with: MoneyEntity
    expose_translated :memo
    expose :associated_vendor_service_category, with: VendorServiceCategoryEntity
    expose :originating_ledger, with: SimpleLedgerEntity
    expose :receiving_ledger, with: SimpleLedgerEntity
  end

  class DetailedPaymentAccountLedgerEntity < BaseEntity
    include AutoExposeBase
    include AutoExposeDetail
    expose :currency
    expose :vendor_service_categories, with: VendorServiceCategoryEntity
    expose :combined_book_transactions, with: BookTransactionEntity
    expose :balance, with: MoneyEntity
  end

  class DetailedPaymentAccountEntity < BaseEntity
    include AutoExposeBase
    include AutoExposeDetail
    expose :member, with: MemberEntity
    expose :vendor, with: VendorEntity
    expose :is_platform_account
    expose :ledgers, with: DetailedPaymentAccountLedgerEntity
    expose :total_balance, with: MoneyEntity
    expose :originated_funding_transactions, with: FundingTransactionEntity
  end

  class OfferingEntity < BaseEntity
    include AutoExposeBase
    expose_translated :description
    expose :period_end, as: :closes_at
    expose :period_begin, as: :opens_at
  end

  class OfferingFulfillmentOptionEntity < BaseEntity
    include AutoExposeBase
    expose_translated :description
    expose :type
    expose :ordinal
    expose :offering_id
    expose :address, with: AddressEntity, safe: true
  end

  class OfferingProductEntity < BaseEntity
    include AutoExposeBase
    expose :closed_at
    expose :product_id
    expose_translated :product_name, &self.delegate_to(:product, :name)
    expose :vendor_name, &self.delegate_to(:product, :vendor, :name)
    expose :customer_price, with: MoneyEntity
    expose :undiscounted_price, with: MoneyEntity
    expose :closed?, as: :is_closed
  end

  class OrderEntity < BaseEntity
    include AutoExposeBase
    expose :order_status
    expose :fulfillment_status
    expose :admin_status_label, as: :status_label
    expose :checkout_id
    expose :member, with: MemberEntity, &self.delegate_to(:checkout, :cart, :member)
  end

  class EligibilityConstraintEntity < BaseEntity
    include AutoExposeBase
    expose :id
    expose :name
  end
end
