# frozen_string_literal: true

require "grape"
require "suma/api"

class Suma::API::Commerce < Suma::API::V1
  include Suma::Service::Types
  include Suma::API::Entities
  TimeRangeEntity = Suma::Service::Entities::TimeRange

  resource :commerce do
    desc "Return all commerce offerings that are not closed"
    get :offerings do
      # TODO: render list of available (not closed) offerings
      open_offerings = Suma::Commerce::Offerings.available
      present_collection open_offerings, with: CommerceOfferingsEntity
    end
  end

  class CommerceOfferingsEntity < BaseEntity
    expose :id
    expose :description
    expose :period, with: TimeRangeEntity
  end
end
