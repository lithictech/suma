# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::OrganizationMembershipVerifications < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

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
  end

  class DetailedMembershipVerificationEntity < MembershipVerificationEntity
  end

  resource :organization_membership_verifications do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Organization::MembershipVerification,
      MembershipVerificationEntity,
    )

    resource :todo do
      Suma::AdminAPI::CommonEndpoints.list(
        self,
        Suma::Organization::MembershipVerification,
        MembershipVerificationEntity,
        dataset: lambda(&:todo),
      )
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Organization::MembershipVerification,
      DetailedMembershipVerificationEntity,
    )

    route_param :id, type: Integer do
      helpers do
        def lookup_writeable!
          (v = Suma::Organization::MembershipVerification[params[:id]]) or forbidden!
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
    end
  end
end
