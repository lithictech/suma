# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Members < Suma::AdminAPI::V1
  ALL_TIMEZONES = Set.new(TZInfo::Timezone.all_identifiers)

  resource :members do
    desc "Return all members, newest first"
    params do
      use :pagination
      use :ordering, model: Suma::Member
      use :searchable
    end
    get do
      ds = Suma::Member.dataset
      if (email_like = search_param_to_sql(params, :email))
        name_like = search_param_to_sql(params, :name)
        phone_like = phone_search_param_to_sql(params)
        ds = ds.where(email_like | name_like | phone_like)
      end

      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: Suma::AdminAPI::MemberEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup_member!
          (member = Suma::Member[params[:id]]) or not_found!
          return member
        end
      end

      desc "Return the member"
      get do
        member = lookup_member!
        present member, with: Suma::AdminAPI::DetailedMemberEntity
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
        present member, with: Suma::AdminAPI::DetailedMemberEntity
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
        present member, with: Suma::AdminAPI::DetailedMemberEntity
      end

      get :bank_accounts do
        member = lookup_member!
        present_collection member.bank_accounts, with: Suma::AdminAPI::BankAccountEntity
      end

      get :payment_instruments do
        member = lookup_member!
        present_collection member.bank_accounts, with: Suma::AdminAPI::PaymentInstrumentEntity
      end
    end
  end
end
