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
    params do
      requires :offering_id, type: Integer
      requires :product_id, type: Integer
      requires :customer_price, allow_blank: false, type: JSON do
        use :funding_money
      end
      requires :undiscounted_price, allow_blank: false, type: JSON do
        use :funding_money
      end
    end
    post :create do
      Suma::Commerce::Offering.db.transaction do
        (offering = Suma::Commerce::Offering[params[:offering_id]]) or forbidden!
        (product = Suma::Commerce::Product[params[:product_id]]) or forbidden!
        op = Suma::Commerce::OfferingProduct.create(
          offering:,
          product:,
          customer_price: params[:customer_price],
          undiscounted_price: params[:undiscounted_price],
        )
        created_resource_headers(op.id, op.admin_link)
        status 200
        present op, with: DetailedCommerceOfferingProductEntity
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self, Suma::Commerce::OfferingProduct, DetailedCommerceOfferingProductEntity,
    )
  end
end
