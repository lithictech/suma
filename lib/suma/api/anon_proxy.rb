# frozen_string_literal: true

require "suma/api"
require "suma/service/types"

require "suma/async/process_anon_proxy_inbound_webhookdb_relays"

class Suma::API::AnonProxy < Suma::API::V1
  include Suma::Service::Types
  include Suma::API::Entities

  def self.extract_email_from_request(request)
    begin
      params = JSON.parse(request.body.read)
    rescue JSON::ParserError
      return nil
    end
    request.body.rewind
    return params["email"]
  end

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

        params do
          requires :email, type: String, coerce_with: NormalizedEmail
        end
        Suma::RackAttack.throttle_many(
          "/anon_proxy/message_bomb_to_email",
          # Users should not need more than 3 of these within a minute.
          {limit: 3, period: 1.minute},
          # Prevent malicious use by rate limiting across a longer period.
          {limit: 10, period: 1.hour},
        ) do |request|
          next unless request.path.include?("/v1/anon_proxy/vendor_accounts/#{request.params[:id]}/start_email")
          Suma::API::AnonProxy.extract_email_from_request(request)
        end
        Suma::RackAttack.throttle_many(
          "/anon_proxy/email_bomb_from_ip",
          # Same limits as above
          {limit: 3, period: 1.minute},
          {limit: 10, period: 1.hour},
        ) do |request|
          next unless request.path.include?("/v1/anon_proxy/vendor_accounts/#{request.params[:id]}/start_email")
          request.env.fetch("rack.remote_ip")
        end
        post :start_email do
          apva = lookup
          member = current_member
          member.update(email: params["email"])
          Suma::Member::ResetCode.replace_active(member, transport: "email")
          status 200
          present(
            apva,
            with: MutationAnonProxyVendorAccountEntity,
            all_vendor_accounts: Suma::AnonProxy::VendorAccount.for(current_member, as_of: current_time),
          )
        end

        params do
          requires :email, type: String, coerce_with: NormalizedEmail
          requires :token, type: String, allow_blank: false
        end
        Suma::RackAttack.throttle_many(
          "/anon_proxy/reset_code_enumeration",
          # Users should only need 4 attempts within a couple minutes to check a code
          {limit: 4, period: 2.minutes},
          # Codes expire after 15 minutes anyway, don't allow more than a reasonable number of attempts
          {limit: 8, period: 20.minutes},
        ) do |request|
          check_path = "/v1/anon_proxy/vendor_accounts/#{request.params[:id]}/start_email_verification"
          next unless request.path.include?(check_path)
          request.env.fetch("rack.remote_ip")
        end
        Suma::RackAttack.throttle_many(
          "/anon_proxy/distributed_reset_code_enumeration",
          # Prevent a determined attacker with distributed IPs from being able to test many codes for a phone number.
          {limit: 50, period: 20.minutes},
        ) do |request|
          check_path = "/v1/anon_proxy/vendor_accounts/#{request.params[:id]}/start_email_verification"
          next unless request.path.include?(check_path)
          Suma::API::AnonProxy.extract_email_from_request(request)
        end
        post :verify_email do
          # Here member must pass in email so we can search the member.
          Suma::Member::ResetCode.use_code_with_token(params[:token]) do |code|
            md = code.message_delivery
            unless (code.member === current_member) &&
                (current_member === params[:email]) &&
                # It's possible for a code to be expired before we have even sent the delivery
                md &&
                # Verification must happen through 'email' transport
                md.transport_type == "email" &&
                # deliveries can potentially be aborted therefore a having nil message id
                md.transport_message_id &&
                # Verification must happen through the verification template
                Suma::Message::EmailTransport.verification_delivery?(md)
              merror!(403, "Sorry, that token is invalid or the email is not in our system.", code: "invalid_otp")
            end
          end
          apva = lookup
          contact = Suma::AnonProxy::MemberContact.create(
            member: apva.member,
            email: params[:email],
            relay_key: "fake-relay",
          )
          apva.contact = contact
          apva.save_changes

          # status 200
          # present apva
        end

        post :configure do
          apva = lookup
          apva.provision_contact
          status 200
          present(
            apva,
            with: MutationAnonProxyVendorAccountEntity,
            all_vendor_accounts: Suma::AnonProxy::VendorAccount.for(current_member, as_of: current_time),
          )
        end

        post :make_auth_request do
          apva = lookup
          # lp = Suma::Lyft::Pass.from_config
          # lp.authenticate
          # lp.send_lyftpass_invitation_to_member
          areq = apva.auth_request
          got = Suma::Http.execute(
            areq.delete(:http_method).downcase.to_sym,
            areq.delete(:url),
            logger: self.logger,
            skip_error: true,
            **areq,
          )
          apva.update(latest_access_code_requested_at: current_time) if got.code < 300
          status got.code
          present got.parsed_response
        end

        # Endpoint for long-polling for a new magic link for a vendor account.
        # It's important we long rather than short poll because
        # we want to be as light as possible on the user's device.
        post :poll_for_new_magic_link do
          apva = lookup
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
    expose :email_verification_required?, as: :email_verification_required
    expose :sms
    expose :sms_required?, as: :sms_required
    expose :address
    expose :address_required?, as: :address_required
    expose :instructions do |va|
      txt = va.configuration.instructions.string
      txt % {address: va.address || ""}
    end
    expose :auth_request
    expose :magic_link do |instance|
      instance.latest_access_code_is_recent? ? instance.latest_access_code_magic_link : nil
    end
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

  class AnonProxyVendorAccountPollResultEntity < BaseEntity
    expose :found_change
    expose :vendor_account, with: AnonProxyVendorAccountEntity
  end
end
