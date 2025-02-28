# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::Charges < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedChargeEntity < ChargeEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :member, with: MemberEntity
    expose :mobility_trip, with: MobilityTripEntity
    expose :commerce_order, with: OrderEntity
    expose :line_items, with: ChargeLineItemEntity
    expose :associated_funding_transactions, with: FundingTransactionEntity
  end

  class ChargeEntityWithMember < ChargeEntity
    include Suma::AdminAPI::Entities
    expose :member, with: MemberEntity
  end

  resource :charges do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Charge,
      ChargeEntityWithMember,
      search_params: [:opaque_id],
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Charge,
      DetailedChargeEntity,
    )
  end
end
