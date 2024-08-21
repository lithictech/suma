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

    expose :orders, with: OrderEntity
  end

  resource :commerce_offering_products do
    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Commerce::OfferingProduct,
      DetailedCommerceOfferingProductEntity,
      access: Suma::Member::RoleAccess::ADMIN_COMMERCE,
    ) do
      params do
        requires(:offering, type: JSON) { use :model_with_id }
        requires(:product, type: JSON) { use :model_with_id }
        requires(:customer_price, allow_blank: false, type: JSON) { use :funding_money }
        requires(:undiscounted_price, allow_blank: false, type: JSON) { use :funding_money }
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Commerce::OfferingProduct,
      DetailedCommerceOfferingProductEntity,
      access: Suma::Member::RoleAccess::ADMIN_COMMERCE,
    )

    route_param :id, type: Integer do
      params do
        optional(:customer_price, allow_blank: false, type: JSON) { use :funding_money }
        optional(:undiscounted_price, allow_blank: false, type: JSON) { use :funding_money }
        at_least_one_of :customer_price, :undiscounted_price
      end
      post do
        check_role_access!(admin_member, :write, :admin_commerce)
        Suma::Commerce::OfferingProduct.db.transaction do
          (m = Suma::Commerce::OfferingProduct[params[:id]]) or forbidden!
          new_op = m.with_changes(
            customer_price: params[:customer_price], undiscounted_price: params[:undiscounted_price],
          )
          created_resource_headers(new_op.id, new_op.admin_link)
          status 200
          present new_op, with: DetailedCommerceOfferingProductEntity
        end
      end
    end
  end
end
