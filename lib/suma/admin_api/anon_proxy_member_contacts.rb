# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::AnonProxyMemberContacts < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class DetailedMemberContactEntity < AnonProxyMemberContactEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail

    expose :phone
    expose :email
    expose :external_relay_id
    expose :vendor_accounts, with: AnonProxyVendorAccountEntity
  end

  resource :anon_proxy_member_contacts do
    params do
      requires(:member, type: JSON) { use :model_with_id }
      requires :type, type: Symbol, values: [:email, :phone]
    end
    post :provision do
      (member = Suma::Member[params[:member][:id]]) or forbidden!
      contact, created = Suma::AnonProxy::MemberContact.ensure_anonymous_contact(member, params[:type])
      unless created
        msg = "Member #{member.name} already has a contact for #{params[:type]}. Delete it first and try again."
        adminerror!(409, msg)
      end
      created_resource_headers(contact.id, contact.admin_link)
      status 200
      present contact, with: DetailedMemberContactEntity
    end

    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::AnonProxy::MemberContact,
      AnonProxyMemberContactEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::AnonProxy::MemberContact,
      DetailedMemberContactEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::AnonProxy::MemberContact,
      DetailedMemberContactEntity,
    ) do
      params do
        optional :email, type: String
        optional :phone, type: String
      end
    end

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::AnonProxy::MemberContact,
      DetailedMemberContactEntity,
    )
  end
end
