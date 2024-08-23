# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::MessageDeliveries < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class MessageBodyEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :content
    expose :mediatype
  end

  class MessageDeliveryWithBodiesEntity < MessageDeliveryEntity
    include Suma::AdminAPI::Entities
    expose :bodies, with: MessageBodyEntity
  end

  resource :message_deliveries do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Message::Delivery,
      MessageDeliveryEntity,
      search_params: [:to, :template],
    )

    desc "Return the delivery with the last ID"
    get :last do
      check_role_access!(admin_member, :read, :admin_members)
      delivery = Suma::Message::Delivery.last
      present delivery, with: MessageDeliveryWithBodiesEntity
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Message::Delivery,
      MessageDeliveryWithBodiesEntity,
    )
  end
end
