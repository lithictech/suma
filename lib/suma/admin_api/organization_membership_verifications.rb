# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::OrganizationMembershipVerifications < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities
  include Suma::AdminAPI::ServerSentEvents

  class MembershipVerificationNoteEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :creator, with: MemberEntity
    expose :edited_at
    expose :editor, with: MemberEntity
    expose :content
    expose :content_html
  end

  class VerificationListEntity < OrganizationMembershipVerificationEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail

    expose :account_number
    expose :available_events, &self.delegate_to(:state_machine, :available_events)
    expose :front_partner_conversation_status
    expose :front_member_conversation_status
    expose :notes, with: MembershipVerificationNoteEntity
    expose :duplicate_risk
  end

  class DetailedMembershipVerificationEntity < VerificationListEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail

    expose :available_events, &self.delegate_to(:state_machine, :available_events)
    expose :front_partner_conversation_status
    expose :front_member_conversation_status
    expose :address, with: AddressEntity, &self.delegate_to(:membership, :member, :legal_entity, :address, safe: true)
    expose :notes, with: MembershipVerificationNoteEntity
    expose :audit_logs, with: AuditLogEntity
    expose :partner_outreach_front_conversation_id
    expose :member_outreach_front_conversation_id
    expose :duplicates do |instance|
      instance.find_duplicates.map(&:as_json)
    end
  end

  resource :organization_membership_verifications do
    params do
      use :pagination
      use :ordering, default: :created_at, values: [:status, :member, :organization, :created_at]
      use :searchable
      optional :status, type: Symbol, default: :todo
    end
    get do
      access = Suma::AdminAPI::Access.read_key(Suma::Organization::Membership::Verification)
      check_role_access!(admin_member, :read, access)
      ds = Suma::Organization::Membership::Verification.dataset
      # Join the verification with its membership, member, and organization, so we can search by name
      ds = ds.association_join(:membership).
        left_join(:members, {id: Sequel[:membership][:member_id]}, qualify: :deep).
        left_join(
          :organizations,
          {
            id: Sequel.function(
              :coalesce,
              Sequel[:membership][:verified_organization_id],
              Sequel[:membership][:former_organization_id],
            ),
          },
          qualify: :deep,
        )
      if (status = params[:status]) == :todo
        ds = ds.todo
      elsif status == :all
        nil
      elsif status
        ds = ds.where(status: status.to_s)
      end
      if (search = params[:search]).present?
        srch = "%#{search}%"
        ds = ds.where(
          Sequel[:members][:name].ilike(srch) |
            Sequel[:organizations][:name].ilike(srch) |
            Sequel[:membership][:unverified_organization_name].ilike(srch),
        )
      end
      orderings = if (order = params[:order_by]) == :member
                    [Sequel[:members][:name]]
      elsif order == :organization
        [Sequel.function(:coalesce, Sequel[:organizations][:name], Sequel[:membership][:unverified_organization_name])]
      else
        [Sequel[:organization_membership_verifications][order]]
      end
      orderings << Sequel[:organization_membership_verifications][:id]
      orderings.each do |expr|
        ds = ds.order_append(Sequel.send(params[:order_direction], expr))
      end
      ds = paginate(ds, params)
      ds = ds.select(Sequel[:organization_membership_verifications][Sequel.lit("*")])
      header Suma::SSE::TOKEN_HEADER, Suma::SSE::Auth.generate_token
      header("Suma-Front-Enabled", "1") if Suma::Frontapp.configured?
      present_collection ds, with: VerificationListEntity
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Organization::Membership::Verification,
      DetailedMembershipVerificationEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Organization::Membership::Verification,
      DetailedMembershipVerificationEntity,
    ) do
      route_setting :do_not_check_sse_token, true
      params do
        optional :account_number, type: String
        optional :status, type: String
        optional :partner_outreach_front_conversation_id, type: String
        optional :member_outreach_front_conversation_id, type: String
      end
    end

    route_param :id, type: Integer do
      helpers do
        def lookup_writeable!
          (v = Suma::Organization::Membership::Verification[params[:id]]) or forbidden!
          check_role_access!(admin_member, :write, :admin_members)
          return v
        end
      end

      params do
        requires :event
      end
      post :transition do
        v = lookup_writeable!
        v.process(params[:event]) or adminerror!(400, "Could not #{params[:event]} verification")
        status 200
        present v, with: VerificationListEntity
      end

      post :begin_partner_outreach do
        v = lookup_writeable!
        v.begin_partner_outreach
        status 200
        present v, with: VerificationListEntity
      end

      post :begin_member_outreach do
        v = lookup_writeable!
        v.begin_member_outreach
        status 200
        present v, with: VerificationListEntity
      end

      route_setting :do_not_check_sse_token, true
      post :rebuild_duplicates do
        v = lookup_writeable!
        sleep 1
        v.cached_duplicates_key = ""
        status 200
        present v, with: DetailedMembershipVerificationEntity
      end

      resource :notes do
        params do
          requires :content, type: String
        end
        post do
          v = lookup_writeable!
          v.add_note(
            content: params[:content],
            creator: admin_member,
            created_at: Time.now,
          )
          status 200
          present v, with: VerificationListEntity
        end

        route_param :note_id, type: Integer do
          params do
            requires :content
          end
          post do
            v = lookup_writeable!
            (note = v.notes_dataset[params[:note_id]]) or forbidden!
            note.update(
              content: params[:content],
              editor: admin_member,
              edited_at: Time.now,
            )
            status 200
            present v, with: VerificationListEntity
          end
        end
      end
    end
  end
end
