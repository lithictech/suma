# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"
require "suma/api" unless defined? Suma::API

module Suma::API::Entities
  AddressEntity = Suma::Service::Entities::Address
  LegalEntityEntity = Suma::Service::Entities::LegalEntityEntity
  MoneyEntity = Suma::Service::Entities::Money
  TimeRangeEntity = Suma::Service::Entities::TimeRange

  class BaseEntity < Suma::Service::Entities::Base; end

  class CurrencyEntity < BaseEntity
    expose :symbol
    expose :code
    expose :funding_minimum_cents
    expose :funding_step_cents
    expose :cents_in_dollar
    expose :payment_method_types
  end

  class LocaleEntity < BaseEntity
    expose :code
    expose :language
    expose :native
  end

  class ImageEntity < BaseEntity
    expose_translated :caption
    expose :url, &self.delegate_to(:uploaded_file, :absolute_url)
  end

  class OrganizationEntity < BaseEntity
    expose :name
    expose :slug
  end

  class PaymentInstrumentEntity < BaseEntity
    expose :id
    expose :created_at
    expose :id, as: :payment_instrument_id
    expose :payment_method_type
    expose :can_use_for_funding?, as: :can_use_for_funding
    expose :institution
    expose :name
    expose :last4
    expose :key do |inst|
      "#{inst.payment_method_type}-#{inst.id}"
    end
  end

  class VendorServiceRateEntity < BaseEntity
    expose :id
    expose :localization_key
    expose :localization_vars
  end

  class VendorServiceEntity < BaseEntity
    expose :id
    expose :external_name, as: :name
    expose :vendor_name, &self.delegate_to(:vendor, :name)
    expose :vendor_slug, &self.delegate_to(:vendor, :slug)
  end

  class MobilityTripEntity < BaseEntity
    expose :id
    expose :vehicle_id
    expose :vendor_service, as: :provider, with: VendorServiceEntity
    expose :vendor_service_rate, as: :rate, with: VendorServiceRateEntity
    expose :begin_lat
    expose :begin_lng
    expose :began_at
    expose :end_lat
    expose :end_lng
    expose :ended_at
    expose :total_cost, with: MoneyEntity, &self.delegate_to(:charge, :discounted_subtotal, safe: true)
    expose :discount_amount, with: MoneyEntity, &self.delegate_to(:charge, :discount_amount, safe: true)
  end

  class CurrentMemberEntity < Suma::Service::Entities::CurrentMember
    expose :unclaimed_orders_count, &self.delegate_to(:orders_dataset, :available_to_claim, :count)
    expose :ongoing_trip
    expose :read_only_mode?, as: :read_only_mode
    expose :read_only_reason
    expose :usable_payment_instruments, with: PaymentInstrumentEntity
    expose :admin_member, expose_nil: false, with: Suma::Service::Entities::CurrentMember do |_|
      self.impersonation.is? ? self.impersonation.admin_member : nil
    end
    expose :show_private_accounts do |m|
      !Suma::AnonProxy::VendorAccount.for(m).empty?
    end
  end

  class LedgerLineUsageDetailsEntity < Grape::Entity
    expose :code
    expose :args
  end

  class LedgerLineEntity < BaseEntity
    expose :id
    expose :opaque_id
    expose :apply_at, as: :at
    expose_translated :memo
    expose :amount, with: MoneyEntity do |inst, opts|
      if inst.directed?
        inst.amount
      elsif (ledger = opts[:ledger])
        inst.receiving_ledger === ledger ? inst.amount : (inst.amount * -1)
      else
        raise "Must use directed ledger lines or pass :ledger option"
      end
    end
    expose :usage_details, with: LedgerLineUsageDetailsEntity
  end

  class LedgerEntity < BaseEntity
    expose :id
    expose :name
    expose_translated :contribution_text
    expose :balance, with: MoneyEntity
  end
end
