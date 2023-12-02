# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceOfferingProducts < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedCommerceOfferingProductEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :offering, with: OfferingEntity
    expose :product, with: ProductEntity
    expose :customer_price, with: MoneyEntity
    expose :undiscounted_price, with: MoneyEntity
    expose :closed_at
  end

  resource :commerce_offering_products do
    Suma::AdminAPI::CommonEndpoints.create(
      self, Suma::Commerce::OfferingProduct, DetailedCommerceOfferingProductEntity,
    ) do
      params do
        requires(:offering, type: JSON) { use :model_with_id }
        requires(:product, type: JSON) { use :model_with_id }
        requires(:customer_price, allow_blank: false, type: JSON) { use :funding_money }
        requires(:undiscounted_price, allow_blank: false, type: JSON) { use :funding_money }
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self, Suma::Commerce::OfferingProduct, DetailedCommerceOfferingProductEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self, Suma::Commerce::OfferingProduct, DetailedCommerceOfferingProductEntity,
    ) do
      params do
        optional(:customer_price, allow_blank: false, type: JSON) { use :funding_money }
        optional(:undiscounted_price, allow_blank: false, type: JSON) { use :funding_money }
      end
    end
  end
end
