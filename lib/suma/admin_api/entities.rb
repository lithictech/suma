# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"

module Suma::AdminAPI::Entities
  MoneyEntity = Suma::Service::Entities::Money
  LegalEntityEntity = Suma::Service::Entities::LegalEntityEntity
  TimeRangeEntity = Suma::Service::Entities::TimeRange
  AddressEntity = Suma::Service::Entities::Address

  class BaseEntity < Suma::Service::Entities::Base; end

  # Simple exposure of common fields that can be used for lists of entities.
  module AutoExposeBase
    def self.included(ctx)
      ctx.expose :id, if: ->(o) { o.respond_to?(:id) }
      ctx.expose :created_at, if: ->(o) { o.respond_to?(:created_at) }
      ctx.expose :soft_deleted_at, if: ->(o) { o.respond_to?(:soft_deleted_at) }
    end
  end

  # More extensive exposure of common fields for when we show
  # detailed entities, or limited lists.
  module AutoExposeDetail
    def self.included?(ctx)
      ctx.expose :updated_at, if: ->(o) { o.respond_to?(:updated_at) }
      ctx.expose :admin_link, if: ->(o, _) { o.respond_to?(:admin_link) }
      # Always expose an external links array when we mix this in
      ctx.expose :external_links do |inst|
        inst.respond_to?(:external_links) ? inst.external_links : []
      end
    end
  end

  class CurrentMemberEntity < Suma::Service::Entities::CurrentMember
    expose :impersonating, with: Suma::Service::Entities::CurrentMember do |_|
      self.impersonation.is? ? self.impersonation.current_member : nil
    end
  end

  class RoleEntity < BaseEntity
    expose :id
    expose :name
  end

  class PaymentInstrumentEntity < BaseEntity
    include AutoExposeBase
    expose :payment_method_type
    expose :admin_link
    expose :to_display, as: :display
    expose :legal_entity_display
  end

  class AuditMemberEntity < BaseEntity
    expose :id
    expose :email
    expose :name
  end

  class MemberEntity < BaseEntity
    include AutoExposeBase
    expose :email
    expose :name
    expose :phone
    expose :timezone
  end

  class MessageDeliveryEntity < BaseEntity
    include AutoExposeBase
    expose :template
    expose :transport_type
    expose :transport_service
    expose :transport_message_id
    expose :sent_at
    expose :aborted_at
    expose :to
  end

  class BankAccountEntity < PaymentInstrumentEntity
    include AutoExposeDetail
    expose :verified_at
    expose :routing_number
    expose :account_number
    expose :account_type
  end
end
