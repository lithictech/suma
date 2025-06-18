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

        rescue_from Sequel::UniqueConstraintViolation do |e|
          invalid!(e.to_s)
        end

        rescue_from Sequel::ValidationFailed do |e|
          invalid!(e.errors.full_messages, message: e.message)
        end

        rescue_from Suma::UploadedFile::MismatchedContentType do |e|
          invalid!(e.message)
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

  # Mixin for endpoints using Server Sent Events.
  # The endpoints should:
  # - Return an event subscription auth token in some GET endpoint (usually the list or resource being subscribed to)
  # - Include that auth token in all mutating methods using the same header.
  # - Any events that happen during a reuqest using that auth token, will not be published to the subscriber
  #   registered with that token. This avoids notifying about an action the user took, in the same browser window.
  module ServerSentEvents
    def self.included(mod)
      super
      mod.instance_eval do
        before do
          header_check = Suma::Http::UNSAFE_METHODS.include?(env["REQUEST_METHOD"]) &&
            !route_setting(:do_not_check_sse_token)
          if header_check && !headers.key?(Suma::SSE::TOKEN_HEADER)
            # If we are taking an action that would result in an update, make sure the caller has included
            # an event token so we don't replay events back to the client.
            msg = "Endpoint uses Server Sent Events so requires a '#{Suma::SSE::TOKEN_HEADER}' header"
            adminerror!(400, msg, code: "missing_sse_token")
          end
          Suma::SSE.current_session_id = headers[Suma::SSE::TOKEN_HEADER]
        end

        after do
          Suma::SSE.current_session_id = nil
        end
      end
    end
  end
end

require "suma/admin_api/common_endpoints"
