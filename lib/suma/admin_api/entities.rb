# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"
require "suma/admin_api" unless defined? Suma::AdminAPI

module Suma::AdminAPI
  CurrentCustomerEntity = Suma::Service::Entities::CurrentCustomer
  MoneyEntity = Suma::Service::Entities::Money
  LegalEntityEntity = Suma::Service::Entities::LegalEntityEntity
  TimeRangeEntity = Suma::Service::Entities::TimeRange
  AddressEntity = Suma::Service::Entities::Address

  class BaseEntity < Suma::Service::Entities::Base; end

  class RoleEntity < BaseEntity
    expose :id
    expose :name
  end

  class AuditCustomerEntity < BaseEntity
    expose :id
    expose :email
    expose :name
  end

  class CustomerEntity < BaseEntity
    expose :id
    expose :created_at
    expose :soft_deleted_at
    expose :email
    expose :name
    expose :phone
    expose :timezone
  end

  class CustomerJourneyEntity < BaseEntity
    expose :id
    expose :created_at
    expose :processed_at
    expose :name
    expose :message
  end

  class CustomerResetCodeEntity < BaseEntity
    expose :id
    expose :created_at
    expose :transport
    expose :token
    expose :used
    expose :expire_at
  end

  class CustomerSessionEntity < BaseEntity
    expose :id
    expose :created_at
    expose :user_agent
    expose :peer_ip, &self.delegate_to(:peer_ip, :to_s)
    expose :ip_lookup_link do |instance|
      "https://whatismyipaddress.com/ip/#{instance.peer_ip}"
    end
  end

  class MessageBodyEntity < BaseEntity
    expose :id
    expose :content
    expose :mediatype
  end

  class MessageDeliveryEntity < BaseEntity
    expose :id
    expose :created_at
    expose :updated_at
    expose :template
    expose :transport_type
    expose :transport_service
    expose :transport_message_id
    expose :sent_at
    expose :aborted_at
    expose :to
  end

  class MessageDeliveryWithBodiesEntity < MessageDeliveryEntity
    expose :bodies, with: MessageBodyEntity
  end

  class DetailedCustomerEntity < CustomerEntity
    expose :opaque_id
    expose :note
    expose :roles do |instance|
      instance.roles.map(&:name)
    end
    expose :available_roles do |_|
      Suma::Role.order(:name).select_map(:name)
    end
    expose :legal_entity, with: LegalEntityEntity
    expose :journeys, with: CustomerJourneyEntity
    expose :reset_codes, with: CustomerResetCodeEntity
    expose :sessions, with: CustomerSessionEntity
  end
end
