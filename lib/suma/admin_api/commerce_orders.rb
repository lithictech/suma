# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceOrders < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class ListOrderEntity < OrderEntity
    expose :total_item_count
  end

  class CheckoutItemEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :id
    expose :offering_product, with: OfferingProductEntity
    expose :quantity
    expose :checkout_id
  end

  class CheckoutEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :undiscounted_cost, with: MoneyEntity
    expose :customer_cost, with: MoneyEntity
    expose :savings, with: MoneyEntity
    expose :handling, with: MoneyEntity
    expose :tax, with: MoneyEntity
    expose :total, with: MoneyEntity
    expose :payment_instrument, with: PaymentInstrumentEntity
    expose :fulfillment_option, with: OfferingFulfillmentOptionEntity
  end

  class DetailedCommerceOrderEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    include AutoExposeDetail
    expose :order_status
    expose :fulfillment_status
    expose :admin_status_label, as: :status_label
    expose :serial
    expose :charge, with: ChargeWithPricesEntity
    expose :audit_logs, with: AuditLogEntity
    expose :offering, with: OfferingEntity, &self.delegate_to(:checkout, :cart, :offering)
    expose :checkout, with: CheckoutEntity
    expose :items, with: CheckoutItemEntity, &self.delegate_to(:checkout, :items)
    expose :member, with: MemberEntity, &self.delegate_to(:checkout, :cart, :member)
  end

  resource :commerce_orders do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Commerce::Order,
      ListOrderEntity,
    )
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Commerce::Order,
      DetailedCommerceOrderEntity,
    )
  end
end
