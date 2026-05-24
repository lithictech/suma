# frozen_string_literal: true

require "suma/service/entities"
require "suma/service/collection"

module Suma::AdminAPI::Entities
  class MoneyEntity < Suma::Service::Entities::Money; end
  class LegalEntityEntity < Suma::Service::Entities::LegalEntityEntity; end
  class AddressEntity < Suma::Service::Entities::Address; end

  class TranslatedTextEntity < Suma::Service::Entities::Base
    expose :en
    expose :es
  end

  class NamedValueEntity < Suma::Service::Entities::Base
    expose :name
    expose :value
  end

  class ImageEntity < Suma::Service::Entities::Base
    expose :url, &self.delegate_to(:uploaded_file, :absolute_url)
    expose :caption, with: TranslatedTextEntity
  end

  class BaseEntity < Suma::Service::Entities::Base
    class << self
      def expose_image(name, &block)
        self.expose(name, with: ImageEntity) do |instance, options|
          evaluate_exposure(name, block, instance, options)
        end
        self.expose("#{name}_caption", with: TranslatedTextEntity) do |instance, options|
          img = evaluate_exposure(name, block, instance, options)
          img&.caption
        end
      end
    end
  end

  # Base class for models. Allows exposure of related associations via #expore_related,
  # and automatic route create during CommonEndpoints.get_one.
  class BaseModelEntity < BaseEntity
    class << self
      attr_accessor :exposed_related

      def inherited(subclass)
        super
        subclass.exposed_related = self.exposed_related.dup
        subclass.model(self.model)
      end

      def model(type=nil)
        return @model if type.nil?
        @model = type
        self.exposed_related ||= []
      end

      # Expose a list field of this entity.
      # The field is exposed with a Collection entity so it can be paginated.
      #
      # NOTE: Callers must implement these collection endpoints, usually through CommonEndpoints.get_one.
      # See CommonEndpoints.related.
      #
      # @param name [Symbol] Related name. The subroute gets this name if exposed with CommonEndpoints.get_one.
      #   The instance must have a <name>_dataset method or name must be an association.
      # @param with [Class<BaseEntity>] Entity to use in the expsoure.
      # @param as [Symbol] The field on the entity will get this name.
      # @param all [true,false] If true, load all items from the dataset when loading the collection.
      #   This preserves the 'collection' format exposure but does not require pagination.
      #   Useful when we always want to load all resources in admin.
      # @param inherit_permissions [true,false] Some resources, like notes or audit logs,
      #   should inherit the permissions of their parent.
      #   If inherit_permissions is true, the permissions of the parent model are used,
      #   rather than the subresource.
      # @param to_path [Proc] If given, this is called with (instance, options)
      #   to get the PATH_INFO (ie, /members/123) part of the route.
      #   Used for nested related exposures, so /member/123
      #   can nest to something like /payment_accounts/123/ledgers.
      def expose_related(name, with:, as: nil, all: false, inherit_permissions: false, to_path: nil)
        collection_entity = Suma::Service::Collection.prepare_entity(with)
        ds_method = :"#{name}_dataset"
        unless self.model.method_defined?(ds_method)
          raise ArgumentError, "must call #model before using expose_related, got: #{self.model.inspect}" unless
            self.model.respond_to?(:association_reflections)
          assoc = self.model.association_reflections[name]
          raise ArgumentError, "#{self.model} does not has association #{name} or dataset #{ds_method}" if assoc.nil?
          ds_method = assoc.fetch(:dataset_method)
        end
        self.exposed_related << {name:, with:, inherit_permissions:}
        self.expose(name, as:, with: collection_entity) do |instance, options|
          ds = instance.send(ds_method)
          if all
            collection = Suma::Service::Collection.from_array(ds.all)
          else
            ds = ds.paginate(1, Suma::Service.related_list_size)
            collection = Suma::Service::Collection.from_dataset(ds)
          end
          path_info = to_path ? to_path[instance, options] : nil
          collection.url = Suma::Service.request_path(options[:env], path_info) + "/#{name}"
          collection
        end
      end
    end
  end

  # Simple exposure of common fields that can be used for lists of entities.
  module AutoExposeBase
    def self.included(ctx)
      ctx.expose :id, if: ->(o) { o.respond_to?(:id) }
      ctx.expose :created_at, if: ->(o) { o.respond_to?(:created_at) }
      ctx.expose :soft_deleted_at, if: ->(o) { o.respond_to?(:soft_deleted_at) }
      ctx.expose :admin_link, if: ->(o, _) { o.respond_to?(:admin_link) }
      ctx.expose :admin_label, as: :label, if: ->(o, _) { o.respond_to?(:admin_label) }
    end
  end

  # More extensive exposure of common fields for when we show
  # detailed entities, or limited lists.
  module AutoExposeDetail
    def self.included(ctx)
      ctx.expose :updated_at, if: ->(o) { o.respond_to?(:updated_at) } do |inst|
        inst.updated_at || inst.created_at
      end
      ctx.expose :created_by, with: AuditMemberEntity, if: ->(o) { o.respond_to?(:created_by) } do
        inst.created_by
      end
      # Always expose an external links array when we mix this in
      ctx.expose :external_links do |inst|
        inst.respond_to?(:external_links) ? inst.external_links.map(&:as_json) : []
      end
      ctx.expose :admin_actions do |inst|
        inst.respond_to?(:admin_actions) ? inst.admin_actions.map(&:as_json) : []
      end
    end
  end

  # Entity with no custom fields except those from AutoExposeBase.
  class AutoExposedBaseEntity < BaseEntity
    include AutoExposeBase
  end

  class CurrentMemberEntity < Suma::Service::Entities::CurrentMember
    expose :impersonating, with: Suma::Service::Entities::CurrentMember do |_|
      self.current_session.impersonating
    end
  end

  class RoleEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Role
    expose :name
  end

  class OrganizationEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Organization
    expose :name
  end

  class PaymentInstrumentEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Payment::Instrument
    expose :payment_method_type
    expose :legal_entity, with: LegalEntityEntity
    expose :institution_name
    expose :name
    expose :status
  end

  class AuditMemberEntity < BaseEntity
    expose :id
    expose :admin_label, as: :label
    expose :email
    expose :name
    expose :admin_link
  end

  class AuditLogEntity < BaseModelEntity
    expose :id
    expose :at
    expose :event
    expose :to_state
    expose :from_state
    expose :reason
    expose :messages
    expose :actor, with: AuditMemberEntity
  end

  class SupportNoteEntity < BaseModelEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase

    model Suma::Support::Note
    expose :author, with: AuditMemberEntity
    expose :authored_at
    expose :content
    expose :content_html
  end

  class ActivityEntity < BaseModelEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase

    model Suma::Member::Activity
    expose :member, with: AuditMemberEntity
    expose :message_name
    expose :message_vars
    expose :summary
    expose :summary_md
  end

  class MemberEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Member
    expose :email
    expose :name
    expose :phone
    expose :us_phone, as: :formatted_phone
    expose :timezone
    expose :onboarding_verified_at
  end

  class MessageDeliveryEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Message::Delivery
    expose :template
    expose :transport_type
    expose :carrier_key
    expose :transport_message_id
    expose :sent_at
    expose :aborted_at
    expose :to
    expose :formatted_to
    expose :recipient, with: MemberEntity
  end

  class ProgramEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Program
    expose :name, with: TranslatedTextEntity
    expose :description, with: TranslatedTextEntity
    expose :period_begin
    expose :period_end
    expose :ordinal
    expose :app_link
    expose :app_link_text, with: TranslatedTextEntity
  end

  class EligibilityAttributeEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Eligibility::Attribute
    expose :name
    expose :parent, with: self
  end

  class EligibilityAssignmentEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Eligibility::Assignment
    expose :assignee, with: AutoExposedBaseEntity
    expose :assignee_label
    expose :assignee_type
    expose :attribute, with: EligibilityAttributeEntity
  end

  class EligibilityRequirementResourceEntity < BaseEntity
    include AutoExposeBase
  end

  class EligibilityRequirementEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Eligibility::Requirement
    expose :cached_expression_string, as: :expression_formula_str
    expose :all_resources, as: :resources, with: EligibilityRequirementResourceEntity
  end

  class VendorEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Vendor
    expose :name
  end

  class VendorServiceEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Vendor::Service
    expose :internal_name
    expose :external_name
    expose :vendor, with: VendorEntity
    expose :period_begin
    expose :period_end
  end

  class VendorServiceCategoryTerminalEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Vendor::ServiceCategory
    expose :name
    expose :slug
  end

  class VendorServiceCategoryEntity < VendorServiceCategoryTerminalEntity
    expose :parent, with: VendorServiceCategoryTerminalEntity
  end

  class VendorServiceRateUndiscountedrateEntity < BaseEntity
    include AutoExposeBase

    expose :internal_name
  end

  class VendorServiceRateEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Vendor::ServiceRate
    expose :internal_name
    expose :external_name
    expose :unit_offset
    expose :ordinal
    expose :unit_amount, with: MoneyEntity
    expose :surcharge, with: MoneyEntity
    expose :undiscounted_rate, with: VendorServiceRateUndiscountedrateEntity
  end

  class ProgramPricingEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Program::Pricing
    expose :program, with: ProgramEntity
    expose :vendor_service, with: VendorServiceEntity
    expose :vendor_service_rate, with: VendorServiceRateEntity
  end

  class AnonProxyVendorConfigurationEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::AnonProxy::VendorConfiguration
    expose :vendor, with: VendorEntity
    expose :app_install_link
    expose :auth_to_vendor_key
    expose :enabled
  end

  class AnonProxyMemberContactEntity < BaseModelEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase

    model Suma::AnonProxy::MemberContact
    expose :member, with: MemberEntity
    expose :formatted_address
    expose :relay_key
  end

  class AnonProxyVendorAccountMemberContactEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase

    expose :formatted_address
  end

  class AnonProxyVendorAccountEntity < BaseModelEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase

    model Suma::AnonProxy::VendorAccount
    expose :member, with: MemberEntity
    expose :configuration, with: AnonProxyVendorConfigurationEntity
    expose :contact, with: AnonProxyVendorAccountMemberContactEntity
  end

  class ChargeEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Charge
    expose :opaque_id
    expose :discounted_subtotal, with: MoneyEntity
    expose :undiscounted_subtotal, with: MoneyEntity
  end

  class ChargeWithPricesEntity < ChargeEntity
    expose :off_platform_amount, with: MoneyEntity
    expose :cash_paid_from_ledger, with: MoneyEntity
    expose :noncash_paid_from_ledger, with: MoneyEntity
  end

  class MobilityTripEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Mobility::Trip
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

  class SimpleLedgerEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Payment::Ledger
    expose :name
    expose :currency
    expose :account_id
    expose :account_name, &self.delegate_to(:account, :display_name)
  end

  class SimplePaymentAccountEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Payment::Account
    expose :display_name
  end

  class PaymentStrategyEntity < BaseEntity
    include AutoExposeBase

    expose :admin_details_typed, as: :admin_details
  end

  class FundingTransactionEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Payment::FundingTransaction
    expose :status
    expose :amount, with: MoneyEntity
    expose :originating_payment_account, with: SimplePaymentAccountEntity
  end

  class PayoutTransactionEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Payment::PayoutTransaction
    expose :status
    expose :classification
    expose :amount, with: MoneyEntity
    expose :originating_payment_account, with: SimplePaymentAccountEntity
  end

  class BookTransactionEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Payment::BookTransaction
    expose :apply_at
    expose :amount, with: MoneyEntity
    expose :memo, with: TranslatedTextEntity
    expose :associated_vendor_service_category, with: VendorServiceCategoryEntity
    expose :originating_ledger, with: SimpleLedgerEntity
    expose :receiving_ledger, with: SimpleLedgerEntity
    expose :actor, with: AuditMemberEntity
  end

  # class DetailedPaymentAccountLedgerEntity < BaseModelEntity
  #   include AutoExposeBase
  #   include AutoExposeDetail
  #
  #   model Suma::Payment::Ledger
  #   route :payment_ledgers
  #   expose :currency
  #   expose_related :vendor_service_categories, with: VendorServiceCategoryEntity
  #   expose_related :combined_book_transactions, with: BookTransactionEntity
  #   expose :balance, with: MoneyEntity
  # end
  #
  # class DetailedPaymentAccountEntity < BaseModelEntity
  #   include AutoExposeBase
  #   include AutoExposeDetail
  #
  #   model Suma::Payment::Account
  #   expose :member, with: MemberEntity
  #   expose :vendor, with: VendorEntity
  #   expose :is_platform_account
  #   expose :ledgers, with: DetailedPaymentAccountLedgerEntity
  #   expose :total_balance, with: MoneyEntity
  #   expose_related :originated_funding_transactions, with: FundingTransactionEntity
  #   expose_related :originated_payout_transactions, with: PayoutTransactionEntity
  # end

  class PaymentTriggerEntity < BaseModelEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase

    model Suma::Payment::Trigger
    expose :active_during_begin
    expose :active_during_end
  end

  class OfferingEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Commerce::Offering
    expose :description, with: TranslatedTextEntity
    expose :period_end
    expose :period_begin
  end

  class OfferingFulfillmentOptionEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Commerce::OfferingFulfillmentOption
    expose :description, with: TranslatedTextEntity
    expose :type
    expose :ordinal
    expose :offering_id
    expose :address, with: AddressEntity, safe: true
  end

  class OfferingProductEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Commerce::OfferingProduct
    expose :closed_at
    expose :product_id
    expose_translated :product_name, &self.delegate_to(:product, :name)
    expose :vendor_name, &self.delegate_to(:product, :vendor, :name)
    expose :customer_price, with: MoneyEntity
    expose :undiscounted_price, with: MoneyEntity
    expose :closed?, as: :is_closed
  end

  class ProductEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Commerce::Product
    expose :vendor, with: VendorEntity
    expose :name, with: TranslatedTextEntity
    expose :description, with: TranslatedTextEntity
  end

  class OrderEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Commerce::Order
    expose :order_status
    expose :fulfillment_status
    expose :admin_status_label, as: :status_label
    expose :checkout_id
    expose :member, with: MemberEntity, &self.delegate_to(:checkout, :cart, :member)
  end

  # Needed to handle the 1-to-1 between Membership and Verification
  class BaseOrganizationMembershipVerificationEntity < BaseEntity
    include AutoExposeBase

    expose :status
    expose :owner, with: MemberEntity
  end

  class OrganizationMembershipEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Organization::Membership
    expose :member, with: MemberEntity
    expose :verified_organization, with: OrganizationEntity
    expose :unverified_organization_name
    expose :former_organization, with: OrganizationEntity
    expose :organization_label
    expose :formerly_in_organization_at
    expose :membership_type
    expose :verification, with: BaseOrganizationMembershipVerificationEntity
  end

  class OrganizationMembershipVerificationEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Organization::Membership::Verification
    expose :status
    expose :membership, with: OrganizationMembershipEntity
    expose :owner, with: MemberEntity
  end

  class OrganizationRegistrationLinkEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Organization::RegistrationLink
    expose :organization, with: OrganizationEntity
    expose :opaque_id
    expose :ical_dtstart
    expose :ical_dtend
    expose :ical_rrule
  end

  class ChargeLineItemEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Charge::LineItem
    expose :charge_id
    expose :amount, with: MoneyEntity
    expose :memo, with: TranslatedTextEntity
  end

  class MarketingMemberEntity < MemberEntity
    expose :id
    expose :name
    expose :phone
    expose :us_phone, as: :formatted_phone
    expose :admin_link
  end

  class MarketingListEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Marketing::List
    expose :managed
  end

  class MarketingSmsBroadcastEntity < BaseModelEntity
    include AutoExposeBase

    model Suma::Marketing::SmsBroadcast
    expose :sent_at
  end

  class MarketingSmsDispatchEntity < BaseModelEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase

    model Suma::Marketing::SmsDispatch
    expose :member, with: MarketingMemberEntity
    expose :sms_broadcast, with: MarketingSmsBroadcastEntity
    expose :sent_at
    expose :transport_message_id
    expose :status
    expose :last_error
  end
end
