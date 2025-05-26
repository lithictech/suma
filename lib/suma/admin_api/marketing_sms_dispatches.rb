# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingSmsDispatches < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class SmsDispatchEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :sent_at
    expose :member, with: MarketingMemberEntity
    expose :sms_campaign, with: MarketingSmsCampaignEntity
    expose :sent_at
    expose :transport_message_id
  end

  class DetailedSmsDispatchEntity < SmsDispatchEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
  end

  resource :marketing_sms_dispatches do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Marketing::SmsDispatch,
      SmsDispatchEntity,
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
