# frozen_string_literal: true

require "suma/postgres"
require "suma/customer"

class Suma::Customer::Session < Suma::Postgres::Model(:customer_sessions)
  plugin :timestamps

  many_to_one :customer, class: Suma::Customer

  def self.params_for_request(request)
    return {
      peer_ip: request.ip,
      user_agent: request.user_agent || "(unset)",
    }
  end

  def validate
    super
    self.validates_presence :peer_ip
    self.validates_presence :user_agent
    self.validates_presence :customer_id
  end
end
