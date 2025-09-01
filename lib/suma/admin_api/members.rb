# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Members < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class MemberResetCodeEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :transport
    expose :used
    expose :expire_at
    expose :token do |inst, opts|
      ra = opts.fetch(:env).fetch("yosoy").authenticated_object!.member.role_access
      expose_token = ra.can?(:read, ra.admin_sensitive_messages)
      expose_token ? inst.token : ("*" * inst.token.length)
    end
    expose :message_delivery, with: MessageDeliveryEntity
  end

  class MemberSessionEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :user_agent
    expose :peer_ip, &self.delegate_to(:peer_ip, :to_s)
    expose :ip_lookup_link do |instance|
      "https://whatismyipaddress.com/ip/#{instance.peer_ip}"
    end
  end

  class MemberOrderEntity < OrderEntity
    include Suma::AdminAPI::Entities
    expose :total_item_count
    expose :offering, with: OfferingEntity, &self.delegate_to(:checkout, :cart, :offering)
  end

  class MemberVendorAccountEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :latest_access_code
    expose :latest_access_code_magic_link
    expose :vendor, with: VendorEntity, &self.delegate_to(:configuration, :vendor)
  end

  class MemberContactEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :formatted_address
  end

  class PreferencesSubscriptionEntity < BaseEntity
    expose :key
    expose :opted_in
    expose :editable_state
  end

  class PreferencesEntity < BaseEntity
    expose :public_url
    expose :subscriptions, with: PreferencesSubscriptionEntity
    expose :preferred_language_name
  end

  class DetailedMemberEntity < MemberEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :opaque_id
    expose :note
    expose :roles, with: RoleEntity
    expose :onboarding_verified?, as: :onboarding_verified
    expose :previous_phones do |instance|
      instance.previous_phones.map { |s| Suma::PhoneNumber.format_display(s) }
    end
    expose :previous_emails

    expose :activities, with: ActivityEntity
    expose :audit_activities, with: ActivityEntity
    expose :legal_entity, with: LegalEntityEntity
    expose :payment_account, with: DetailedPaymentAccountEntity
    expose :bank_accounts, with: PaymentInstrumentEntity
    expose :charges, with: ChargeEntity
    expose :direct_program_enrollments, with: ProgramEnrollmentEntity
    expose :program_enrollment_exclusions, with: ProgramEnrollmentExclusionEntity
    expose :reset_codes, with: MemberResetCodeEntity
    expose :sessions, with: MemberSessionEntity
    expose :orders, with: MemberOrderEntity
    expose :message_deliveries, with: MessageDeliveryEntity
    expose :preferences!, as: :preferences, with: PreferencesEntity
    expose :anon_proxy_vendor_accounts, as: :vendor_accounts, with: MemberVendorAccountEntity
    expose :anon_proxy_contacts, as: :member_contacts, with: MemberContactEntity
    expose :organization_memberships, with: OrganizationMembershipEntity
    expose :marketing_lists, with: MarketingListEntity
    expose :marketing_sms_dispatches, with: MarketingSmsDispatchEntity
  end

  ALL_TIMEZONES = Set.new(TZInfo::Timezone.all_identifiers)

  resource :members do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Member,
      MemberEntity,
      exporter: Suma::Member::Exporter,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Member,
      DetailedMemberEntity,
    )
    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Member,
      DetailedMemberEntity,
      around: lambda do |rt, m, &block|
        roles = rt.params.delete(:roles)
        block.call
        if roles
          rt.check_admin_role_access!(:write, :admin_management)
          role_models = Suma::Role.where(id: roles.map { |r| r[:id] }).all
          m.replace_roles(role_models)
          m.audit_activity(
            "rolechange",
            action: m.roles.map(&:name).join(", "),
          )
        end
      end,
    ) do
      params do
        optional :name, type: String
        optional :note, type: String
        optional :email, type: String
        optional :phone, type: Integer
        optional :timezone, type: String, values: ALL_TIMEZONES
        optional :roles, type: Array[JSON] do
          use :model_with_id
        end
        optional :onboarding_verified, type: Boolean
        optional :legal_entity, type: JSON do
          optional :id, type: Integer
          optional :name, type: String
          optional :address, type: JSON do
            use :address
          end
        end
        optional :organization_memberships, type: Array[JSON] do
          optional :id, type: Integer
          optional(:verified_organization, type: JSON) { use :model_with_id }
        end
      end
    end

    route_param :id, type: Integer do
      helpers do
        def lookup_member!
          (member = Suma::Member[params[:id]]) or forbidden!
          return member
        end
      end

      post :close do
        check_admin_role_access!(:write, Suma::Member)
        member = lookup_member!
        admin = admin_member
        member.db.transaction do
          member.audit_activity(
            "accountclosed",
            prefix: "Admin #{admin.email} closed member #{member.email} account",
          )
          member.soft_delete unless member.soft_deleted?
        end
        status 200
        present member, with: DetailedMemberEntity
      end
    end
  end
end
