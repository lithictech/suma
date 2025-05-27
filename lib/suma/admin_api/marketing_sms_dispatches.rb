# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingSmsDispatches < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedSmsDispatchEntity < MarketingSmsDispatchEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :can_cancel?, as: :can_cancel
    expose :canceled?, as: :canceled
  end

  resource :marketing_sms_dispatches do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Marketing::SmsDispatch,
      MarketingSmsDispatchEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Marketing::SmsDispatch,
      DetailedSmsDispatchEntity,
    )

    route_param :id, type: Integer do
      post :cancel do
        (o = Suma::Marketing::SmsDispatch[params[:id]]) or forbidden!
        adminerror!(409, "Dispatch already sent") if o.sent?
        o.cancel
        o.save_changes
        created_resource_headers(o.id, o.admin_link)
        status 200
        present o, with: DetailedSmsDispatchEntity
      end
    end
  end
end
