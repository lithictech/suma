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
    expose :symbol, documentation: {type: String}
    expose :code, documentation: {type: String}
    expose :funding_minimum_cents, documentation: {type: Integer}
    expose :funding_maximum_cents, documentation: {type: Integer}
    expose :funding_step_cents, documentation: {type: Integer}
    expose :cents_in_dollar, documentation: {type: Integer}
    expose_array :payment_method_types, documentation: {type: String}
  end

  class LocaleEntity < BaseEntity
    expose :code, documentation: {type: String}
    expose :language, documentation: {type: String}
    expose :native, documentation: {type: String}
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
    expose :institution, documentation: {type: String}
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
    expose_array :line_items, MobilityChargeLineItemEntity
  end

  class MobilityTripParsedAddressEntity < BaseEntity
    expose :part1, documentation: {type: String}
    expose :part2, documentation: {type: String}
  end

  class MobilityTripEntity < BaseEntity
    expose :id
    expose :vehicle_id
    expose :vehicle_type
    expose :vendor_service, as: :provider, with: VendorServiceEntity
    expose :begin_lat
    expose :begin_lng
    expose :begin_address_parsed, as: :begin_address, with: MobilityTripParsedAddressEntity
    expose :began_at
    expose :end_lat
    expose :end_lng
    expose :end_address_parsed, as: :end_address, with: MobilityTripParsedAddressEntity
    expose :ended_at
    expose :ongoing?, as: :ongoing
    expose :charge, with: MobilityChargeEntity
    expose :duration_minutes, as: :minutes, documentation: {type: Integer}
    expose :image, with: ImageEntity
  end

  class PreferencesSubscriptionEntity < BaseEntity
    expose :key
    expose :opted_in, documentation: {type: :Boolean}
    expose :editable_state
  end

  class MemberPreferencesEntity < BaseEntity
    expose_array :subscriptions, PreferencesSubscriptionEntity
  end

  class RegistrationLinkEntity < BaseEntity
    expose :organization_name, &self.delegate_to(:organization, :name)
    expose_translated :intro

    def self.link_and_code_from_env(env)
      at = env.fetch("now")
      cookies = env.fetch("rack.request.cookie_hash")
      return Suma::Organization::RegistrationLink.and_code_from_params(cookies, at:)
    end
  end

  class CurrentMemberEntity < Suma::Service::Entities::CurrentMember
    expose :unclaimed_orders_count, &self.delegate_to(:orders_dataset, :available_to_claim, :count)
    expose :ongoing_trip, with: MobilityTripEntity
    expose :read_only_mode?, as: :read_only_mode
    expose :read_only_reason
    expose_array :public_payment_instruments, as: :payment_instruments, with: PaymentInstrumentEntity
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
    expose :chargeable_cash_balance, with: MoneyEntity do |m|
      b = m.payment_account&.cash_ledger&.balance
      Suma::Payment.chargeable_balance?(b || Money.new(0)) ? b : nil
    end

    expose :finished_survey_topics, documentation: {type: String, array: true} do |m|
      m.db[:member_surveys].where(member_id: m.id).select_map(:topic).sort
    end
    expose :registration_link, with: RegistrationLinkEntity do |_|
      RegistrationLinkEntity.link_and_code_from_env(self.options.fetch(:env))&.link
    end
  end

  class LedgerLineUsageDetailsEntity < Grape::Entity
    expose :code
    expose :args, documentation: {type: Suma::Service::Entities::RecordString}
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

    expose_array :usage_details, LedgerLineUsageDetailsEntity
  end

  class LedgerEntity < BaseEntity
    expose :id
    expose :name
    expose_translated :contribution_text
    expose :balance, with: MoneyEntity
  end
end
