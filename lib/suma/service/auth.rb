# frozen_string_literal: true

require "suma/yosoy"

class Suma::Service::Auth
  class Middleware < Suma::Yosoy::Middleware
    def serialize_into_session(user) = user.pk
    def serialize_from_session(key) = Suma::Member[key]
    def inactivity_timeout = Suma::Service.max_session_age
  end

  class Impersonation < Suma::Yosoy::Impersonation
    def target_scope = :member
    def parent_scope = :admin
    def current_member = self.target_user
    def admin_member = self.parent_user
  end
end
