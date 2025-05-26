# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingLists < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class ListEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :name
    expose :managed
  end

  class MarketingMemberEntity < MemberEntity
    expose :id
    expose :name
    expose :phone
    expose :admin_link
  end

  class DetailedListEntity < ListEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :members, with: MarketingMemberEntity
  end

  resource :marketing_lists do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Marketing::List,
      ListEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Marketing::List,
      DetailedListEntity,
    )
  end
end
