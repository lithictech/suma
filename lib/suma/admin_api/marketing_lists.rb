# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingLists < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedListEntity < MarketingListEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :members, with: MarketingMemberEntity
    expose :sms_broadcasts, with: MarketingSmsBroadcastEntity
  end

  resource :marketing_lists do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Marketing::List,
      MarketingListEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Marketing::List,
      DetailedListEntity,
    ) do
      params do
        requires :label, type: String
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Marketing::List,
      DetailedListEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Marketing::List,
      DetailedListEntity,
      around: lambda do |rt, m, &block|
        rt.adminerror!(403, "Managed lists cannot be edited") if m.managed?
        members = rt.params.delete(:members)
        block.call
        m.member_pks = members.map { |l| l.fetch(:id) } if
          members
      end,
    ) do
      params do
        optional :label, type: String
        optional :members, type: Array
      end
    end
  end
end
