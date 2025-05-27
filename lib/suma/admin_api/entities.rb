# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"

module Suma::AdminAPI::Entities
  MoneyEntity = Suma::Service::Entities::Money
  LegalEntityEntity = Suma::Service::Entities::LegalEntityEntity
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
    def self.included(ctx)
      ctx.expose :updated_at, if: ->(o) { o.respond_to?(:updated_at) } do |inst|
        inst.updated_at || inst.created_at
      end
      # Always expose an external links array when we mix this in
      ctx.expose :external_links do |inst|
        inst.respond_to?(:external_links) ? inst.external_links : []
      end
    end
  end

  class CurrentMemberEntity < Suma::Service::Entities::CurrentMember
    expose :impersonating, with: Suma::Service::Entities::CurrentMember do |_|
      self.current_session.impersonating
    end
  end

  class RoleEntity < BaseEntity
    expose :id
    expose :name
    expose :label
  end

  class TranslatedTextEntity < BaseEntity
    expose :en
    expose :es
  end

  class ImageEntity < BaseEntity
    expose_translated :caption
    expose :url, &self.delegate_to(:uploaded_file, :absolute_url)
  end

  class OrganizationEntity < BaseEntity
    include AutoExposeBase
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

  class ActivityEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :member, with: AuditMemberEntity
    expose :message_name
    expose :message_vars
    expose :summary
  end

  class MemberEntity < BaseEntity
    include AutoExposeBase
    expose :email
    expose :name
    expose :phone
    expose :timezone
    expose :onboarding_verified_at
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

  class ProgramEntity < BaseEntity
    include AutoExposeBase
    expose :name, with: TranslatedTextEntity
    expose :description, with: TranslatedTextEntity
    expose :period_begin
    expose :period_end
    expose :ordinal
    expose :app_link
    expose :app_link_text, with: TranslatedTextEntity
  end

  class ProgramEnrolleeEntity < BaseEntity
    include AutoExposeBase
    expose :name do |inst|
      inst.is_a?(Suma::Role) ? inst.name.titleize : inst.name
    end
  end

  class ProgramEnrollmentEntity < BaseEntity
    include AutoExposeBase
    expose :admin_link
    expose :program, with: ProgramEntity
    expose :enrollee, with: ProgramEnrolleeEntity
    expose :enrollee_type
    expose :approved_at
    expose :unenrolled_at
    expose :program_active do |pe|
      pe.program_active_at?(Time.now)
    end
  end

  class VendorEntity < BaseEntity
    include AutoExposeBase
    expose :name
  end

  class VendorServiceEntity < BaseEntity
    include AutoExposeBase
    expose :external_name, as: :name
    expose :vendor, with: VendorEntity
    expose :period_begin
    expose :period_end
  end

  class VendorServiceCategoryEntity < BaseEntity
    expose :id
    expose :name
    expose :slug
  end

  class VendorServiceRateEntity < BaseEntity
    include AutoExposeBase
    expose :name
    expose :unit_amount, with: MoneyEntity
    expose :surcharge, with: MoneyEntity
    expose :unit_offset
    expose :undiscounted_amount, with: MoneyEntity, &self.delegate_to(:undiscounted_rate, :unit_amount, safe: true)
    expose :undiscounted_surcharge, with: MoneyEntity, &self.delegate_to(:undiscounted_rate, :surcharge, safe: true)
  end

  class VendorConfigurationEntity < BaseEntity
    include AutoExposeBase
    expose :vendor, with: VendorEntity
    expose :app_install_link
    expose :auth_to_vendor_key
    expose :enabled
  end

  class ChargeEntity < BaseEntity
    include AutoExposeBase
    expose :opaque_id
    expose :discounted_subtotal, with: MoneyEntity
    expose :undiscounted_subtotal, with: MoneyEntity
  end

  class MobilityTripEntity < BaseEntity
    include AutoExposeBase
    expose :vehicle_id
    expose :begin_lat
    expose :begin_lng
    expose :began_at
    expose :end_lat
    expose :end_lng
    expose :ended_at
    expose :member, with: MemberEntity
    expose :vendor_service, with: VendorServiceEntity
    expose :vendor_service_rate, with: VendorServiceRateEntity
    expose :total_cost, with: MoneyEntity, &self.delegate_to(:charge, :discounted_subtotal, safe: true)
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

  class PayoutTransactionEntity < BaseEntity
    include AutoExposeBase
    expose :status
    expose :classification
    expose :amount, with: MoneyEntity
    expose :originating_payment_account, with: SimplePaymentAccountEntity
  end

  class BookTransactionEntity < BaseEntity
    include AutoExposeBase
    expose :apply_at
    expose :amount, with: MoneyEntity
    expose :memo, with: TranslatedTextEntity
    expose :associated_vendor_service_category, with: VendorServiceCategoryEntity
    expose :originating_ledger, with: SimpleLedgerEntity
    expose :receiving_ledger, with: SimpleLedgerEntity
    expose :actor, with: AuditMemberEntity
  end

  class DetailedPaymentAccountLedgerEntity < BaseEntity
    include AutoExposeBase
    include AutoExposeDetail
    expose :currency
    expose :vendor_service_categories, with: VendorServiceCategoryEntity
    expose :combined_book_transactions, with: BookTransactionEntity
    expose :balance, with: MoneyEntity
    expose :label do |inst|
      inst.vendor_service_categories.map(&:name).sort.join(", ")
    end
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
    expose :originated_payout_transactions, with: PayoutTransactionEntity
  end

  class PaymentTriggerEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :label
    expose :active_during_begin
    expose :active_during_end
  end

  class OfferingEntity < BaseEntity
    include AutoExposeBase
    expose :description, with: TranslatedTextEntity
    expose :period_end
    expose :period_begin
  end

  class OfferingFulfillmentOptionEntity < BaseEntity
    include AutoExposeBase
    expose :description, with: TranslatedTextEntity
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

  class ProductEntity < BaseEntity
    include AutoExposeBase
    expose :vendor, with: VendorEntity
    expose :name, with: TranslatedTextEntity
    expose :description, with: TranslatedTextEntity
  end

  class OrderEntity < BaseEntity
    include AutoExposeBase
    expose :order_status
    expose :fulfillment_status
    expose :admin_status_label, as: :status_label
    expose :checkout_id
    expose :member, with: MemberEntity, &self.delegate_to(:checkout, :cart, :member)
  end

  class OrganizationMembershipEntity < BaseEntity
    include AutoExposeBase
    expose :member, with: MemberEntity
    expose :verified_organization, with: OrganizationEntity
    expose :unverified_organization_name
    expose :former_organization, with: OrganizationEntity
    expose :formerly_in_organization_at
    expose :membership_type
  end

  class ChargeLineItemEntity < BaseEntity
    include AutoExposeBase
    expose :charge_id
    expose :amount, with: MoneyEntity
    expose :memo, with: TranslatedTextEntity
    expose :book_transaction, with: BookTransactionEntity
  end

  class MarketingMemberEntity < MemberEntity
    expose :id
    expose :name
    expose :us_phone, as: :phone
    expose :admin_link
  end

  class MarketingListEntity < BaseEntity
    include AutoExposeBase
    expose :label
    expose :managed
  end

  class MarketingSmsBroadcastEntity < BaseEntity
    include AutoExposeBase
    expose :sent_at
    expose :label
  end

  class MarketingSmsDispatchEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :member, with: MarketingMemberEntity
    expose :sms_broadcast, with: MarketingSmsBroadcastEntity
    expose :sent_at
    expose :transport_message_id
    expose :status
    expose :last_error
  end
end
