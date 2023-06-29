# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Members < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

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

    route_param :id, type: Integer do
      helpers do
        def lookup_member!
          (member = Suma::Member[params[:id]]) or forbidden!
          return member
        end
      end

      desc "Return the member"
      get do
        member = lookup_member!
        present member, with: DetailedMemberEntity
      end

      desc "Update the member"
      params do
        optional :name, type: String
        optional :note, type: String
        optional :email, type: String
        optional :phone, type: Integer
        optional :timezone, type: String, values: ALL_TIMEZONES
        optional :roles, type: Array[String]
      end
      post do
        member = lookup_member!
        fields = params
        member.db.transaction do
          if (roles = fields.delete(:roles))
            member.remove_all_roles
            roles.uniq.each { |r| member.add_role(Suma::Role[name: r]) }
          end
          set_declared(member, params)
          member.save_changes
        end
        status 200
        present member, with: DetailedMemberEntity
      end

      post :close do
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

  class DetailedMemberEntity < MemberEntity
    include Suma::AdminAPI::Entities
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
    expose :payment_account, with: DetailedPaymentAccountEntity
    expose :bank_accounts, with: PaymentInstrumentEntity
    expose :charges, with: ChargeEntity
    expose :eligibility_constraints, &self.delegate_to(:unified_eligibility_constraints)

    expose :activities, with: MemberActivityEntity
    expose :reset_codes, with: MemberResetCodeEntity
    expose :sessions, with: MemberSessionEntity
    expose :orders, with: MemberOrderEntity
  end
end
