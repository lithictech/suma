# frozen_string_literal: true

require "grape"
require "suma/api"

class Suma::API::Commerce < Suma::API::V1
  include Suma::Service::Types
  include Suma::API::Entities

  resource :commerce do
    desc "Return all commerce offerings that are not closed"
    get :offerings do
      t = Time.now.to_time
      ds = Suma::Commerce::Offering.available_at(t)
      present_collection ds, with: CommerceOfferingsEntity
    end
  end

  class CommerceOfferingsEntity < BaseEntity
    expose :id
    expose :description
    expose :period, with: Suma::Service::Entities::TimeRange
  end
end
