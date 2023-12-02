# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceOfferingFulfillmentOptions < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class Entity < OfferingFulfillmentOptionEntity; end
  class DetailedEntity < OfferingFulfillmentOptionEntity; end

  resource :commerce_offering_fulfillment_options do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Commerce::OfferingFulfillmentOption,
      Entity,
      translation_search_params: [:description],
    )
    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Commerce::OfferingFulfillmentOption,
      DetailedEntity,
    ) do
      params do
        requires(:offering, type: JSON) { use :model_with_id }
        requires :ordinal, type: Integer
        requires :type, type: String, values: Suma::Commerce::OfferingFulfillmentOption::TYPES
        requires :description, type: JSON
        optional(:address, type: JSON) { use :address }
      end
    end
    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Commerce::OfferingFulfillmentOption, DetailedEntity)
    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Commerce::OfferingFulfillmentOption,
      DetailedEntity,
    ) do
      params do
        optional :ordinal, type: Integer
        optional :type, type: String, values: Suma::Commerce::OfferingFulfillmentOption::TYPES
        optional :description, type: JSON
        optional(:address, type: JSON) { use :address }
      end
    end
  end
end
