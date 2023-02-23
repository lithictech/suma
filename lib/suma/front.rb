# frozen_string_literal: true

require "frontapp"

require "suma"
require "suma/http"

module Suma::Front
  include Appydays::Configurable
  extend Suma::MethodUtilities

  class << self
    # @return [Frontapp::Client]
    attr_accessor :client
  end

  configurable(:front) do
    setting :auth_token, "get-from-front-add-to-env"

    after_configured do
      self.client = Frontapp::Client.new(auth_token: self.auth_token, user_agent: Suma::Http.user_agent)
    end
  end
end
