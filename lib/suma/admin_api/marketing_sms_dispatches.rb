# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingSmsDispatches < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class SmsDispatchEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :sent_at
    expose :member, with: MarketingMemberEntity
    expose :sms_campaign, with: SmsCampaignEntity
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
  end
end
