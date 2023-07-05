# frozen_string_literal: true

module Suma::AnonProxy
  include Appydays::Configurable

  configurable(:anon_proxy) do
    setting :postmark_email_server, "in-dev.mysuma.org"
    setting :email_provider, "fake"
  end
end

require "suma/anon_proxy/email"
