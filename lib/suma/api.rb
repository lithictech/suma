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
          def verified_member!
            c = current_member
            forbidden! unless c.phone_verified?
            return c
          end

          def unsafe_member_lookup(forbid: false)
            if (token = params["token"]).present?
              c = Suma::Member[opaque_id: token]
            elsif (email = params[:lookup_email]).present?
              c = Suma::Member.with_email(email.strip)
            end
            forbidden! if forbid && c.nil?
            return c
          end

          params :unsafe_member_lookup do
            optional :lookup_email, type: String
            optional :token, type: String
          end

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
            h = Suma::API::CurrentMemberEntity.represent(c, env:)
            j = h.to_json
            b64 = Base64.strict_encode64(j)
            header "Suma-Current-Member", b64
          end
        end

        before do
          Sentry.configure_scope do |scope|
            scope.set_tags(application: "public-api")
          end
        end
      end
    end
  end
end
