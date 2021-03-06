# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"
require "suma/admin_api" unless defined? Suma::AdminAPI

module Suma::AdminAPI
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

  class MemberActivityEntity < BaseEntity
    include AutoExposeBase
    expose :message_name
    expose :message_vars
    expose :summary
  end

  class MemberResetCodeEntity < BaseEntity
    include AutoExposeBase
    expose :transport
    expose :token
    expose :used
    expose :expire_at
  end

  class MemberSessionEntity < BaseEntity
    include AutoExposeBase
    expose :user_agent
    expose :peer_ip, &self.delegate_to(:peer_ip, :to_s)
    expose :ip_lookup_link do |instance|
      "https://whatismyipaddress.com/ip/#{instance.peer_ip}"
    end
  end

  class MessageBodyEntity < BaseEntity
    include AutoExposeBase
    expose :content
    expose :mediatype
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

  class MessageDeliveryWithBodiesEntity < MessageDeliveryEntity
    expose :bodies, with: MessageBodyEntity
  end

  class BankAccountEntity < PaymentInstrumentEntity
    include AutoExposeDetail
    expose :verified_at
    expose :routing_number
    expose :account_number
    expose :account_type
  end

  class DetailedMemberEntity < MemberEntity
    include AutoExposeDetail
    expose :opaque_id
    expose :note
    expose :roles do |instance|
      instance.roles.map(&:name)
    end
    expose :available_roles do |_|
      Suma::Role.order(:name).select_map(:name)
    end
    expose :legal_entity, with: LegalEntityEntity
    expose :activities, with: MemberActivityEntity
    expose :reset_codes, with: MemberResetCodeEntity
    expose :sessions, with: MemberSessionEntity
  end

  class DetailedBankAccountEntity < BankAccountEntity
    include AutoExposeDetail
  end
end
