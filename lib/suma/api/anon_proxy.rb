# frozen_string_literal: true

require "suma/api"

class Suma::API::AnonProxy < Suma::API::V1
  include Suma::API::Entities

  resource :anon_proxy do
    resource :vendor_accounts do
      get do
        member = current_member
        status 200
        present_collection Suma::AnonProxy::VendorAccount.for(member), with: AnonProxyVendorAccountEntity
      end

      route_param :id, type: Integer do
        helpers do
          def lookup
            c = current_member
            apva = c.anon_proxy_vendor_accounts_dataset[params[:id]]
            merror!(403, "No anonymous proxy vendor account with that id", code: "resource_not_found") if
              apva.nil?
            merror!(409, "Anon proxy vendor config is not enabled", code: "resource_not_found") unless
              apva.configuration.enabled?
            return apva
          end
        end

        post :configure do
          apva = lookup
          apva.provision_contact
          status 200
          present(
            apva,
            with: MutationAnonProxyVendorAccountEntity,
            all_vendor_accounts: Suma::AnonProxy::VendorAccount.for(current_member),
          )
        end
      end
    end
  end

  class AnonProxyVendorAccountEntity < BaseEntity
    include Suma::API::Entities
    expose :id
    expose :email
    expose :email_required?, as: :email_required
    expose :sms
    expose :sms_required?, as: :sms_required
    expose_translated :instructions, &self.delegate_to(:configuration, :instructions)
    expose :vendor_name, &self.delegate_to(:configuration, :vendor, :name)
    expose :vendor_slug, &self.delegate_to(:configuration, :vendor, :slug)
    expose :vendor_image, with: ImageEntity, &self.delegate_to(:configuration, :vendor, :images, :first)
  end

  class MutationAnonProxyVendorAccountEntity < AnonProxyVendorAccountEntity
    include Suma::API::Entities
    expose :all_vendor_accounts, with: AnonProxyVendorAccountEntity do |_inst, opts|
      opts.fetch(:all_vendor_accounts)
    end
  end
end