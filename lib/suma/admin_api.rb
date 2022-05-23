# frozen_string_literal: true

require "grape"

require "suma"
require "suma/service"

# API is the namespace module for Admin API resources.
module Suma::AdminAPI
  require "suma/admin_api/entities"

  # Split this out since some admin endpoints are unauthed,
  # but otherwise we want it by default.
  class BaseV1 < Suma::Service
    def self.inherited(subclass)
      super
      subclass.instance_eval do
        version "v1", using: :path
        format :json

        content_type :csv, "text/csv"

        require "suma/service/helpers"
        helpers Suma::Service::Helpers

        helpers do
          # Set headers pointing to a created resource.
          # Useful when an endpoint like `/mything/1` creates another resource like `/otherthing/2`.
          # Usually we still want to render `mything[1]` but can tell the client about the created resource
          # in case they want to redirect.
          # Also very useful during testing so you can see what was created in the endpoint.
          def created_resource_headers(resource_id, admin_link)
            header "Created-Resource-Id", resource_id.to_s
            header "Created-Resource-Admin", admin_link
          end
        end

        before do
          Sentry.configure_scope do |scope|
            scope.set_tags(application: "admin-api")
          end
        end
      end
    end
  end

  class V1 < BaseV1
    def self.inherited(subclass)
      super
      subclass.instance_eval do
        auth(:admin)
      end
    end
  end
end
