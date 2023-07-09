# frozen_string_literal: true

require "grape"

require "suma"
require "suma/service"

# API is the namespace module for API resources.
module Suma::API
  require "suma/api/entities"

  class V1 < Suma::Service
    def self.inherited(subclass)
      super
      subclass.instance_eval do
        version "v1", using: :path
        format :json

        require "suma/service/helpers"
        helpers Suma::Service::Helpers

        helpers do
          # Set the Suma-Current-Member header to a base64 encoded version
          # of the current member entity.
          #
          # In many places, we update fields about the current member,
          # like when we add funds (removing read-only mode)
          # or begin/end a trip (changing ongoing_trip).
          #
          # We want to avoid re-fetching `/v1/me` when this happens,
          # since it's an extra API call, and we want to avoid
          # any additional API calls.
          #
          # Endpoints can call `add_current_member_header`,
          # which will set the `Suma-Current-Member` header,
          # which is a base64 encoded version of the 'current member' entity.
          #
          # The on the frontend, use `tap(handleUpdateCurrentMember)`,
          # which will look for this header, decode and parse the value,
          # and update the stored user to it.
          def add_current_member_header
            c = current_member
            h = Suma::API::Entities::CurrentMemberEntity.represent(c, env:)
            j = h.to_json
            b64 = Base64.strict_encode64(j)
            header "Suma-Current-Member", b64
          end

          def check_eligibility!(receiver, member)
            return if receiver.eligible_to?(member)
            merror!(403, "Member cannot access due to constraints", code: "eligibility_violation")
          end
        end

        before do
          Sentry.configure_scope do |scope|
            scope.set_tags(application: "public-api")
          end
        end

        rescue_from Stripe::CardError do |e|
          code = Suma::Stripe.localized_error_code(e)
          merror!(402, e.message, code:, more: {stripe_error: e.to_s})
        end
      end
    end
  end
end
