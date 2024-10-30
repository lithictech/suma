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

  class ProgramComponentEntity < BaseEntity
    expose_translated :name
    expose :until
    expose :image, with: ImageEntity
    expose :link
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
    expose :program_component, with: ProgramComponentEntity do |inst|
      Suma::Program::Component.from_vendor_service(inst)
    end
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

  class PreferencesSubscriptionEntity < BaseEntity
    expose :key
    expose :opted_in
    expose :editable_state
  end

  class MemberPreferencesEntity < BaseEntity
    expose :subscriptions, with: PreferencesSubscriptionEntity
  end

  class ProgramEnrollmentEntity < BaseEntity
    expose_translated :name, &self.delegate_to(:program, :name)
    expose_translated :description, &self.delegate_to(:program, :description)
    expose :image, with: ImageEntity, &self.delegate_to(:program, :image?)
  end

  class CurrentMemberEntity < Suma::Service::Entities::CurrentMember
    expose :unclaimed_orders_count, &self.delegate_to(:orders_dataset, :available_to_claim, :count)
    expose :ongoing_trip
    expose :read_only_mode?, as: :read_only_mode
    expose :read_only_reason
    expose :usable_payment_instruments, with: PaymentInstrumentEntity
    expose :active_programs, with: ProgramEnrollmentEntity do |m, opts|
      m.program_enrollments_dataset.active(as_of: opts[:env].fetch(:now)).all
    end
    expose :admin_member, expose_nil: false, with: Suma::Service::Entities::CurrentMember do |_|
      self.current_session.impersonation? ? self.current_session.member : nil
    end
    expose :show_private_accounts do |m|
      !Suma::AnonProxy::VendorAccount.for(m).empty?
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
