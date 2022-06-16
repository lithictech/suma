# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"
require "suma/api" unless defined? Suma::API

module Suma::API
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

  class MobilityMapVehicleEntity < BaseEntity
    expose :c
    expose :p
    expose :d, expose_nil: false
  end

  class OrganizationEntity < BaseEntity
    expose :name
    expose :slug
  end

  class PaymentInstrumentEntity < BaseEntity
    expose :id
    expose :created_at
    expose :payment_method_type
    expose :to_display, as: :display
    expose :can_use_for_funding?, as: :can_use_for_funding
  end

  class MutationPaymentInstrumentEntity < PaymentInstrumentEntity
    expose :all_payment_instruments, with: PaymentInstrumentEntity do |_inst, opts|
      opts.fetch(:all_payment_instruments)
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

  class MobilityMapEntity < BaseEntity
    expose :precision do |_|
      Suma::Mobility::COORD2INT_FACTOR
    end
    expose :refresh do |_|
      30_000
    end
    expose :providers, with: VendorServiceEntity
    expose :escooter, with: MobilityMapVehicleEntity, expose_nil: false
    expose :ebike, with: MobilityMapVehicleEntity, expose_nil: false
  end

  class MobilityVehicleEntity < BaseEntity
    expose :precision do |_|
      Suma::Mobility::COORD2INT_FACTOR
    end
    expose :vendor_service, with: VendorServiceEntity
    expose :vehicle_id
    expose :to_api_location, as: :loc
    expose :rate, with: VendorServiceRateEntity, &self.delegate_to(:vendor_service, :one_rate)
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
  end

  class CurrentMemberEntity < Suma::Service::Entities::CurrentMember
    expose :ongoing_trip, with: MobilityTripEntity
    expose :read_only_mode?, as: :read_only_mode
    expose :read_only_reason
    expose :usable_payment_instruments, with: PaymentInstrumentEntity
  end

  class LedgerLineEntity < BaseEntity
    expose :id
    expose :opaque_id
    expose :apply_at, as: :at
    expose :memo
    expose :amount, with: MoneyEntity do |inst, opts|
      if inst.directed?
        inst.amount
      else
        inst.receiving_ledger === opts.fetch(:ledger) ? inst.amount : (inst.amount * -1)
      end
    end
  end

  class LedgerEntity < BaseEntity
    expose :id
    expose :name
    expose :balance, with: MoneyEntity
  end

  class CustomerDashboardEntity < BaseEntity
    expose :payment_account_balance, with: MoneyEntity
    expose :lifetime_savings, with: MoneyEntity
    expose :ledger_lines, with: LedgerLineEntity
  end

  class LedgersViewEntity < BaseEntity
    expose :total_balance, with: MoneyEntity
    expose :ledgers, with: LedgerEntity
    expose :single_ledger_lines_first_page, with: LedgerLineEntity do |_, opts|
      opts.fetch(:single_ledger_lines_first_page)
    end
    expose :single_ledger_page_count do |_, opts|
      opts.fetch(:single_ledger_page_count)
    end
  end

  class FundingTransactionEntity < BaseEntity
    expose :id
    expose :created_at
    expose :status
    expose :amount, with: MoneyEntity
    expose :memo
  end
end
