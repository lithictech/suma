# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::OrganizationMembershipVerifications < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class MembershipVerificationNoteEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :creator, with: MemberEntity
    expose :edited_at
    expose :editor, with: MemberEntity
    expose :content
  end

  class MembershipVerificationEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    include AutoExposeDetail

    expose :status
    expose :membership, with: OrganizationMembershipEntity
    expose :owner, with: MemberEntity
    expose :available_events, &self.delegate_to(:state_machine, :available_events)
    expose :front_partner_conversation_status
    expose :front_member_conversation_status
    expose :notes, with: MembershipVerificationNoteEntity
  end

  class DetailedMembershipVerificationEntity < MembershipVerificationEntity
  end

  resource :organization_membership_verifications do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Organization::Membership::Verification,
      MembershipVerificationEntity,
    )

    resource :todo do
      Suma::AdminAPI::CommonEndpoints.list(
        self,
        Suma::Organization::Membership::Verification,
        MembershipVerificationEntity,
        dataset: lambda(&:todo),
      )
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Organization::Membership::Verification,
      DetailedMembershipVerificationEntity,
    )

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
        present v, with: DetailedMembershipVerificationEntity
      end

      post :begin_partner_outreach do
        v = lookup_writeable!
        v.begin_partner_outreach
        status 200
        present v, with: DetailedMembershipVerificationEntity
      end

      post :begin_member_outreach do
        v = lookup_writeable!
        v.begin_member_outreach
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
          present v, with: DetailedMembershipVerificationEntity
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
            present v, with: DetailedMembershipVerificationEntity
          end
        end
      end
    end
  end
end
