# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"
require "suma/api" unless defined? Suma::API

module Suma::API
  AddressEntity = Suma::Service::Entities::Address
  CurrentCustomerEntity = Suma::Service::Entities::CurrentCustomer
  LegalEntityEntity = Suma::Service::Entities::LegalEntityEntity
  MoneyEntity = Suma::Service::Entities::Money
  TimeRangeEntity = Suma::Service::Entities::TimeRange

  class BaseEntity < Suma::Service::Entities::Base; end
end
