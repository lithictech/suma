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
