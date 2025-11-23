# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceProducts < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class OfferingProductWithOfferingEntity < OfferingProductEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :offering, with: OfferingEntity
  end

  class DetailedEntity < ProductEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :ordinal
    expose :our_cost, with: MoneyEntity
    expose :inventory do
      expose :max_quantity_per_member_per_offering,
             &self.delegate_to(:inventory!, :max_quantity_per_member_per_offering)
      expose :limited_quantity, &self.delegate_to(:inventory!, :limited_quantity)
      expose :quantity_on_hand, &self.delegate_to(:inventory!, :quantity_on_hand)
      expose :quantity_pending_fulfillment, &self.delegate_to(:inventory!, :quantity_pending_fulfillment)
    end
    expose :offerings, with: OfferingEntity
    expose :orders, with: OrderEntity
    expose :offering_products, with: OfferingProductWithOfferingEntity
    expose_image :image
    expose :vendor_service_categories, with: VendorServiceCategoryEntity
  end

  resource :commerce_products do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Commerce::Product,
      ProductEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Commerce::Product,
      DetailedEntity,
    ) do
      params do
        requires :image, type: File
        optional(:image_caption, type: JSON) { use :translated_text, allow_blank: true }
        requires(:name, type: JSON) { use :translated_text }
        requires(:description, type: JSON) { use :translated_text }
        requires :ordinal, type: Float
        requires(:our_cost, type: JSON) { use :money }
        requires(:vendor, type: JSON) { use :model_with_id }
        optional(:vendor_service_categories, type: Array, coerce_with: lambda(&:values)) { use :model_with_id }
        optional :inventory, type: JSON do
          optional :max_quantity_per_member_per_offering, type: Integer
          optional :limited_quantity, type: Boolean
          optional :quantity_on_hand, type: Integer
          optional :quantity_pending_fulfillment, type: Integer
        end
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Commerce::Product,
      DetailedEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Commerce::Product,
      DetailedEntity,
    ) do
      params do
        optional :image, type: File
        optional(:image_caption, type: JSON) { use :translated_text, allow_blank: true }
        optional(:name, type: JSON) { use :translated_text }
        optional(:description, type: JSON) { use :translated_text }
        optional :ordinal, type: Float
        optional(:our_cost, type: JSON) { use :money }
        optional(:vendor, type: JSON) { use :model_with_id }
        optional(:vendor_service_categories, type: Array, coerce_with: lambda(&:values)) { use :model_with_id }
        optional :inventory, type: JSON do
          optional :max_quantity_per_member_per_offering, type: Integer
          optional :limited_quantity, type: Boolean
          optional :quantity_on_hand, type: Integer
          optional :quantity_pending_fulfillment, type: Integer
        end
      end
    end
  end
end
