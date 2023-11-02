# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceProducts < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :commerce_products do
    params do
      use :pagination
      use :ordering, model: Suma::Commerce::Product
      use :searchable
    end
    get do
      ds = Suma::Commerce::Product.dataset
      if (nameen_like = search_param_to_sql(params, :name_en))
        namees_like = search_param_to_sql(params, :name_es)
        ds = ds.translation_join(:name, [:en, :es]).where(nameen_like | namees_like)
      end
      # TODO: translation join doesn't work for multiple search terms
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: ProductEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup
          (co = Suma::Commerce::Product[params[:id]]) or forbidden!
          return co
        end
      end

      get do
        co = lookup
        present co, with: DetailedProductEntity
      end
    end
  end

  class OfferingProductWithOfferingEntity < OfferingProductEntity
    include Suma::AdminAPI::Entities
    expose :offering, with: OfferingEntity
  end

  class DetailedProductEntity < ProductEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :our_cost, with: MoneyEntity
    expose :max_quantity_per_order, &self.delegate_to(:inventory!, :max_quantity_per_order)
    expose :max_quantity_per_offering, &self.delegate_to(:inventory!, :max_quantity_per_offering)
    expose :offerings, with: OfferingEntity
    expose :orders, with: OrderEntity
    expose :offering_products, with: OfferingProductWithOfferingEntity
  end
end
