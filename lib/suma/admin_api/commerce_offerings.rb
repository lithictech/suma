# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceOfferings < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :commerce_offerings do
    params do
      use :pagination
      use :ordering, model: Suma::Commerce::Offering
      use :searchable
    end
    get do
      ds = Suma::Commerce::Offering.dataset
      if (descriptionen_like = search_param_to_sql(params, :description_en))
        descriptiones_like = search_param_to_sql(params, :description_es)
        ds = ds.translation_join(:description, [:en, :es]).where(descriptionen_like | descriptiones_like)
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: ListCommerceOfferingEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup
          (co = Suma::Commerce::Offering[params[:id]]) or forbidden!
          return co
        end
      end

      get do
        co = lookup
        present co, with: DetailedCommerceOfferingEntity
      end
    end
  end

  class ListCommerceOfferingEntity < OfferingEntity
    expose :product_count
    expose :order_count
  end

  class OrderInOfferingEntity < OrderEntity
    expose :total_item_count
  end

  class DetailedCommerceOfferingEntity < OfferingEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :offering_products, with: OfferingProductEntity
    expose :orders, with: OrderInOfferingEntity
  end
end
