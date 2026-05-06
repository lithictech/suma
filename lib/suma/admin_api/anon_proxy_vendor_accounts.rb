# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::AnonProxyVendorAccounts < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class VendorAccountRegistrationEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase

    expose :external_program_id
    expose :external_registration_id
  end

  class DetailedVendorAccountEntity < AnonProxyVendorAccountEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail

    expose :latest_access_code
    expose :latest_access_code_set_at
    expose :latest_access_code_requested_at
    expose :latest_access_code_magic_link
    expose :pending_closure
    expose :contact, with: AnonProxyMemberContactEntity
    expose :registrations, with: VendorAccountRegistrationEntity
  end

  resource :anon_proxy_vendor_accounts do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::AnonProxy::VendorAccount,
      AnonProxyVendorAccountEntity,
    )
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::AnonProxy::VendorAccount,
      DetailedVendorAccountEntity,
    )
    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::AnonProxy::VendorAccount,
      DetailedVendorAccountEntity,
    ) do
      params do
        optional :latest_access_code, type: String
        optional :latest_access_code_magic_link, type: String
        optional :latest_access_code_set_at, type: Time
        optional :latest_access_code_requested_at, type: Time
        optional :pending_closure, type: Boolean
      end
    end

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::AnonProxy::VendorAccount,
      DetailedVendorAccountEntity,
    )

    route_param :id, type: Integer do
      helpers do
        def lookup!(rw)
          check_admin_role_access!(rw, Suma::AnonProxy::VendorAccount)
          (m = Suma::AnonProxy::VendorAccount[params[:id]]) or forbidden!
          return m
        end
      end

      post :revoke_lime_login do
        a = lookup!(:write)
        a.member.audit_activity("revokelime", action: a)
        Suma::Program::ServiceRevoker.new(dry_run: false).close_lime_account(a)
        created_resource_headers(a.id, a.admin_link)
        admin_action_handler :update
        status 200
        present a, with: DetailedVendorAccountEntity
      end

      post "revoke_lime_login/finish" do
        a = lookup!(:write)
        a.update(pending_closure: false, contact: nil)
        created_resource_headers(a.id, a.admin_link)
        admin_action_handler :update
        status 200
        present a, with: DetailedVendorAccountEntity
      end

      post :revoke_lyft_pass do
        a = lookup!(:write)
        a.member.audit_activity("revokelyft", action: a)
        Suma::Program::ServiceRevoker.new(dry_run: false).revoke_lyft_passes(a.registrations)
        created_resource_headers(a.id, a.admin_link)
        admin_action_handler :update
        status 200
        present a, with: DetailedVendorAccountEntity
      end
    end
  end
end
