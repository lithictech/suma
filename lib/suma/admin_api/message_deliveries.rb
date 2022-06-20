# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::MessageDeliveries < Suma::AdminAPI::V1
  helpers do
    def lookup_delivery(params)
      (batch = Suma::Message::Delivery[params[:id]]) or forbidden!
      return batch
    end
  end

  resource :message_deliveries do
    desc "Return all message deliveries, newest first"
    params do
      use :pagination
      use :ordering, model: Suma::Message::Delivery
      use :searchable
    end
    get do
      ds = Suma::Message::Delivery.dataset
      if (to_like = search_param_to_sql(params, :to))
        criteria = to_like | search_param_to_sql(params, :template)
        ds = ds.where(criteria)
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: Suma::AdminAPI::MessageDeliveryEntity
    end

    desc "Return the delivery with the last ID"
    get :last do
      delivery = Suma::Message::Delivery.last
      present delivery, with: Suma::AdminAPI::MessageDeliveryWithBodiesEntity
    end

    route_param :id, type: Integer do
      desc "Return the delivery"
      get do
        delivery = lookup_delivery(params)
        present delivery, with: Suma::AdminAPI::MessageDeliveryWithBodiesEntity
      end
    end
  end

  resource :members do
    route_param :id, type: Integer do
      resource :message_deliveries do
        desc "Return all message deliveries for member the given members, as recipients or to their emails"
        get do
          ds = Suma::Message::Delivery.to_members(Suma::Member.where(id: params[:id])).order(Sequel.desc(:id))
          present_collection ds, with: Suma::AdminAPI::MessageDeliveryEntity
        end
      end
    end
  end
end
