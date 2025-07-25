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

      resource :signalwire do
        params do
          requires :MessageSid, type: String
          requires :SmsSid, type: String
          requires :AccountSid, type: String
          requires :From, type: String
          requires :To, type: String
          requires :Body, type: String
          requires :NumMedia, type: String
          requires :NumSegments, type: String
        end
        post :webhooks do
          Sentry.set_context(:signalwire, params.to_h)

          empty_xml = <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <Response></Response>
          XML

          orig_to = Suma::PhoneNumber.unformat_e164(params[:To])
          if !Suma::Message::Transport::Sms.allowlisted_phone?(orig_to)
            xml = empty_xml
            Sentry.capture_message("Received webhook for signalwire to not-allowlisted phone")
          elsif (mc = Suma::AnonProxy::MemberContact[phone: orig_to])
            raw_from = params[:From]
            raw_from = Suma::PhoneNumber.unformat_e164?(raw_from) || raw_from
            orig_from = Suma::PhoneNumber.format_display(raw_from)
            forward_to = Suma::PhoneNumber.format_e164(mc.member.phone)
            forward_from = Suma::PhoneNumber.format_e164(Suma::AnonProxy.signalwire_relay_number)
            new_body = "From #{orig_from}: #{params[:Body]}"
            xdoc = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xb|
              xb.Response do
                xb.Message(new_body, from: forward_from, to: forward_to)
              end
            end
            xml = xdoc.to_xml
          else
            xml = empty_xml
            Sentry.capture_message("Received webhook for signalwire for unmatched number")
          end
          env["api.format"] = :binary
          content_type("application/xml")
          body xml
          status 200
        end

        post :errors do
          Sentry.set_context(:signalwire, params.to_h)
          Sentry.capture_message("Received Signalwire error webhook")
          status 200
          present({})
        end
      end
    end
  end

  class AnonProxyVendorAccountEntity < BaseEntity
    include Suma::API::Entities
    expose :id
    expose_translated :instructions, &self.delegate_to(:configuration, :instructions)
    expose :magic_link do |instance|
      instance.latest_access_code_is_recent? ? instance.latest_access_code_magic_link : nil
    end
    expose :needs_attention do |instance|
      instance.needs_attention?(now: self.current_time)
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
