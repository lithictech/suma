# frozen_string_literal: true

require "suma/api"

require "suma/async/process_anon_proxy_inbound_webhookdb_relays"

class Suma::API::AnonProxy < Suma::API::V1
  include Suma::API::Entities

  resource :anon_proxy do
    resource :vendor_accounts do
      get do
        member = current_member
        vas = Suma::AnonProxy::VendorAccount.for(member, as_of: current_time)
        status 200
        present_collection vas, with: AnonProxyVendorAccountEntity
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

        post :make_auth_request do
          apva = lookup
          apva.auth_to_vendor.auth
          apva.update(latest_access_code_requested_at: current_time)
          status 200
          present apva, with: AnonProxyVendorAccountEntity
        end

        # Endpoint for long-polling for a new magic link for a vendor account.
        # It's important we long rather than short poll because
        # we want to be as light as possible on the user's device.
        post :poll_for_new_magic_link do
          apva = lookup
          unless apva.auth_to_vendor.needs_polling?
            resp = {vendor_account: apva, found_change: true}
            status 200
            present(resp, with: AnonProxyVendorAccountPollResultEntity)
            break
          end
          started_polling = Time.now
          found_change = false
          loop do
            code_set_at = apva.latest_access_code_set_at
            if code_set_at && code_set_at > apva.latest_access_code_requested_at
              found_change = true
              break
            end
            apva.refresh
            elapsed = Time.now - started_polling
            break if elapsed > Suma::AnonProxy.access_code_poll_timeout
            Kernel.sleep(Suma::AnonProxy.access_code_poll_interval)
          end
          status 200
          present({vendor_account: apva, found_change:}, with: AnonProxyVendorAccountPollResultEntity)
        end
      end
    end

    resource :relays do
      resource :webhookdb do
        post :webhooks do
          h = env["HTTP_WHDB_WEBHOOK_SECRET"]
          unauthenticated! unless h == Suma::Webhookdb.postmark_inbound_messages_secret
          Suma::Async::ProcessAnonProxyInboundWebhookdbRelays.perform_async
          status 202
          present({o: "k"})
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
    expose :address
    expose :address_required?, as: :address_required
    expose :instructions do |va|
      txt = va.configuration.instructions.string
      txt % {address: va.address || ""}
    end
    expose :magic_link do |instance|
      instance.latest_access_code_is_recent? ? instance.latest_access_code_magic_link : nil
    end
    expose :vendor_name, &self.delegate_to(:configuration, :vendor, :name)
    expose :vendor_slug, &self.delegate_to(:configuration, :vendor, :slug)
    expose :vendor_image, with: ImageEntity, &self.delegate_to(:configuration, :vendor, :images, :first)
  end

  class AnonProxyVendorAccountPollResultEntity < BaseEntity
    include Suma::API::Entities
    expose :found_change
    expose_translated :success_instructions do |inst|
      inst.fetch(:vendor_account).configuration.linked_success_instructions
    end
    expose :vendor_account, with: AnonProxyVendorAccountEntity
  end
end
