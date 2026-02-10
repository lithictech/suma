# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"
require "suma/api" unless defined? Suma::API

module Suma::API::Entities
  AddressEntity = Suma::Service::Entities::Address
  LegalEntityEntity = Suma::Service::Entities::LegalEntityEntity
  MoneyEntity = Suma::Service::Entities::Money

  class BaseEntity < Suma::Service::Entities::Base; end

  class CurrencyEntity < BaseEntity
    expose :symbol
    expose :code
    expose :funding_minimum_cents
    expose :funding_maximum_cents
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

  class PaymentInstrumentEntity < BaseEntity
    expose :id
    expose :created_at
    expose :id, as: :payment_instrument_id
    expose :payment_method_type
    expose :usable_for_funding?, as: :usable_for_funding
    expose :status
    expose :expires_at
    expose :institution
    expose :name
    expose :last4
    expose :key do |inst|
      "#{inst.payment_method_type}-#{inst.id}"
    end
  end

  class VendorServiceEntity < BaseEntity
    expose :id
    expose :external_name, as: :name
    expose :internal_name, as: :slug
    expose :vendor_name, &self.delegate_to(:vendor, :name)
    expose :vendor_slug, &self.delegate_to(:vendor, :slug)
  end

  class MobilityChargeLineItemEntity < BaseEntity
    expose :amount, with: MoneyEntity
    expose_translated :memo
  end

  class MobilityChargeEntity < BaseEntity
    expose :undiscounted_cost, with: MoneyEntity
    expose :customer_cost, with: MoneyEntity
    expose :savings, with: MoneyEntity
    expose :line_items, with: MobilityChargeLineItemEntity
  end

  class MobilityTripEntity < BaseEntity
    expose :id
    expose :vehicle_id
    expose :vehicle_type
    expose :vendor_service, as: :provider, with: VendorServiceEntity
    expose :begin_lat
    expose :begin_lng
    expose :begin_address_parsed, as: :begin_address
    expose :began_at
    expose :end_lat
    expose :end_lng
    expose :end_address_parsed, as: :end_address
    expose :ended_at
    expose :ongoing?, as: :ongoing
    expose :charge, with: MobilityChargeEntity
    expose :duration_minutes, as: :minutes
    expose :image, with: ImageEntity
  end

  class PreferencesSubscriptionEntity < BaseEntity
    expose :key
    expose :opted_in
    expose :editable_state
  end

  class MemberPreferencesEntity < BaseEntity
    expose :subscriptions, with: PreferencesSubscriptionEntity
  end

  class CurrentMemberEntity < Suma::Service::Entities::CurrentMember
    expose :unclaimed_orders_count, &self.delegate_to(:orders_dataset, :available_to_claim, :count)
    expose :ongoing_trip, with: MobilityTripEntity
    expose :read_only_mode?, as: :read_only_mode
    expose :read_only_reason
    expose :public_payment_instruments, as: :payment_instruments, with: PaymentInstrumentEntity
    expose :admin_member, expose_nil: false, with: Suma::Service::Entities::CurrentMember do |_|
      self.current_session.impersonation? ? self.current_session.member : nil
    end
    expose :show_private_accounts do |m, opts|
      !Suma::AnonProxy::VendorAccount.for(m, as_of: opts[:env].fetch("now")).empty?
    end
    expose :preferences!, as: :preferences, with: MemberPreferencesEntity
    expose :has_order_history do |m|
      !m.orders_dataset.empty?
    end
    expose :finished_survey_topics do |m|
      m.db[:member_surveys].where(member_id: m.id).select_map(:topic).sort
    end
  end

  class LedgerLineUsageDetailsEntity < Grape::Entity
    expose :code
    expose :args
  end

  module LedgerLineAmountMixin
    def xyz; end

    def self.included(ctx)
      ctx.expose :amount, with: Suma::API::Entities::MoneyEntity do |inst, opts|
        if inst.directed?
          inst.amount
        elsif (ledger = opts[:ledger])
          inst.receiving_ledger === ledger ? inst.amount : (inst.amount * -1)
        else
          raise "Must use directed ledger lines or pass :ledger option"
        end
      end
    end
  end

  class LedgerLineEntity < BaseEntity
    expose :id
    expose :opaque_id
    expose :apply_at, as: :at
    expose_translated :memo
    include Suma::API::Entities::LedgerLineAmountMixin
    expose :usage_details, with: LedgerLineUsageDetailsEntity
  end

  class LedgerEntity < BaseEntity
    expose :id
    expose :name
    expose_translated :contribution_text
    expose :balance, with: MoneyEntity
  end
end
