# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::Cards < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class CardEntity < PaymentInstrumentEntity
    expose :last4
    expose :brand
    expose :exp_month
    expose :exp_year
  end

  class DetailedCardEntity < CardEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :stripe_id
    expose :member, with: MemberEntity
  end

  resource :cards do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Payment::Card,
      CardEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Payment::Card,
      DetailedCardEntity,
    )
  end
end
