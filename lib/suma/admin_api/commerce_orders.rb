# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceOrders < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :commerce_orders do
    params do
      use :pagination
      use :ordering, model: Suma::Commerce::Order
    end
    get do
      ds = Suma::Commerce::Order.dataset
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: ListOrderEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup
          (co = Suma::Commerce::Order[params[:id]]) or forbidden!
          return co
        end
      end

      get do
        co = lookup
        present co, with: DetailedCommerceOrderEntity
      end
    end
  end

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
    expose :save_payment_instrument
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
    expose :paid_amount, with: MoneyEntity
    expose :funded_amount, with: MoneyEntity
    expose :audit_logs, with: AuditLogEntity
    expose :offering, with: OfferingEntity, &self.delegate_to(:checkout, :cart, :offering)
    expose :checkout, with: CheckoutEntity
    expose :items, with: CheckoutItemEntity, &self.delegate_to(:checkout, :items)
    expose :member, with: MemberEntity, &self.delegate_to(:checkout, :cart, :member)
  end
end
