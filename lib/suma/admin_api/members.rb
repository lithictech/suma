# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Members < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class MemberActivityEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :message_name
    expose :message_vars
    expose :summary
  end

  class MemberResetCodeEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :transport
    expose :token
    expose :used
    expose :expire_at
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

  class MemberEligibilityConstraintEntity < BaseEntity
    expose :status
    expose :constraint, with: Suma::AdminAPI::Entities::EligibilityConstraintEntity
  end

  class MemberVendorAccountEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :latest_access_code
    expose :latest_access_code_magic_link
    expose :vendor, with: VendorEntity, &self.delegate_to(:configuration, :vendor)
  end

  class PreferencesSubscriptionEntity < BaseEntity
    expose :key
    expose :opted_in
    expose :editable_state
  end

  class PreferencesEntity < BaseEntity
    expose :public_url
    expose :subscriptions, with: PreferencesSubscriptionEntity
  end

  class DetailedMemberEntity < MemberEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :opaque_id
    expose :note
    expose :roles, with: RoleEntity
    expose :available_roles, with: RoleEntity do |_|
      Suma::Role.order(:name).all
    end
    expose :onboarding_verified?, as: :onboarding_verified
    expose :onboarding_verified_at

    expose :legal_entity, with: LegalEntityEntity
    expose :payment_account, with: DetailedPaymentAccountEntity
    expose :bank_accounts, with: PaymentInstrumentEntity
    expose :charges, with: ChargeEntity
    expose :eligibility_constraints,
           with: MemberEligibilityConstraintEntity,
           &self.delegate_to(:eligibility_constraints_with_status)

    expose :activities, with: MemberActivityEntity
    expose :reset_codes, with: MemberResetCodeEntity
    expose :sessions, with: MemberSessionEntity
    expose :orders, with: MemberOrderEntity
    expose :message_deliveries, with: MessageDeliveryEntity
    expose :preferences!, as: :preferences, with: PreferencesEntity
    expose :anon_proxy_vendor_accounts, as: :vendor_accounts, with: MemberVendorAccountEntity
    expose :organization_memberships, with: OrganizationMembershipEntity
  end

  ALL_TIMEZONES = Set.new(TZInfo::Timezone.all_identifiers)

  resource :members do
    desc "Return all members, newest first"
    params do
      use :pagination
      use :ordering, model: Suma::Member
      use :searchable
      optional :download, type: String, values: ["csv"]
    end
    get do
      check_role_access!(admin_member, :read, :admin_members)
      ds = Suma::Member.dataset
      if (email_like = search_param_to_sql(params, :email))
        name_like = search_param_to_sql(params, :name)
        phone_like = phone_search_param_to_sql(params)
        ds = ds.where(email_like | name_like | phone_like)
      end
      ds = order(ds, params)

      if params[:download]
        csv = Suma::Member::Exporter.new(ds).to_csv
        env["api.format"] = :binary
        content_type "text/csv"
        body csv
        header["Content-Disposition"] = "attachment; filename=suma-members-export.csv"
      else
        ds = paginate(ds, params)
        present_collection ds, with: MemberEntity
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Member,
      DetailedMemberEntity,
      access: Suma::Member::RoleAccess::ADMIN_MEMBERS,
    )
    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Member,
      DetailedMemberEntity,
      access: Suma::Member::RoleAccess::ADMIN_MEMBERS,
      around: lambda do |rt, m, &block|
        roles = rt.params.delete(:roles)
        block.call
        if roles
          role_models = Suma::Role.where(id: roles.map { |r| r[:id] }).all
          m.replace_roles(role_models)
          summary = m.roles.map(&:name).join(", ")
          m.add_activity(
            message_name: "rolechange",
            summary: "Admin #{rt.admin_member.email} modified roles of #{m.class.name}[#{m.id}]: #{summary}",
            subject_type: m.class.name,
            subject_id: m.id,
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
        check_role_access!(admin_member, :write, :admin_members)
        member = lookup_member!
        admin = admin_member
        member.db.transaction do
          member.add_activity(
            message_name: "accountclosed",
            summary: "Admin #{admin.email} closed member #{member.email} account",
            subject_type: "Suma::Member",
            subject_id: member.id,
          )
          member.soft_delete unless member.soft_deleted?
        end
        status 200
        present member, with: DetailedMemberEntity
      end

      params do
        requires :values, type: Array[JSON] do
          requires :constraint_id, type: Integer
          requires :status, values: ["verified", "pending", "rejected"]
        end
      end
      post :eligibilities do
        check_role_access!(admin_member, :write, :admin_members)
        member = lookup_member!
        admin = admin_member
        member.db.transaction do
          summary = []
          params[:values].each do |h|
            ec = Suma::Eligibility::Constraint[h[:constraint_id]] or
              adminerror!(403, "Unknown eligibility constraint: #{h[:constraint_id]}")
            member.replace_eligibility_constraint(ec, h[:status])
            summary << "#{ec.name} => #{h[:status]}"
          end
          member.add_activity(
            message_name: "eligibilitychange",
            summary: "Admin #{admin.email} modified eligibilities of #{member.email}: #{summary.join(', ')}",
            subject_type: "Suma::Member",
            subject_id: member.id,
          )
        end
        status 200
        present member, with: DetailedMemberEntity
      end
    end
  end
end
