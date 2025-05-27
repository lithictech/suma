# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingLists < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedListEntity < MarketingListEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :members, with: MarketingMemberEntity
    expose :sms_campaigns, with: MarketingSmsCampaignEntity
  end

  resource :marketing_lists do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Marketing::List,
      MarketingListEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Marketing::List,
      DetailedListEntity,
    )
  end
end
