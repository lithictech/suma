# frozen_string_literal: true

require "suma/postgres"
require "suma/customer"

class Suma::Member::Session < Suma::Postgres::Model(:member_sessions)
  plugin :timestamps

  many_to_one :member, class: Suma::Member

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
    self.validates_presence :member_id
  end
end

# Table: customer_sessions
# ----------------------------------------------------------------------------------------------
# Columns:
#  id          | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at  | timestamp with time zone | NOT NULL DEFAULT now()
#  customer_id | integer                  | NOT NULL
#  user_agent  | text                     | NOT NULL
#  peer_ip     | inet                     | NOT NULL
# Indexes:
#  customer_sessions_pkey              | PRIMARY KEY btree (id)
#  customer_sessions_customer_id_index | btree (customer_id)
#  customer_sessions_peer_ip_index     | btree (peer_ip)
#  customer_sessions_user_agent_index  | btree (user_agent)
# Foreign key constraints:
#  customer_sessions_customer_id_fkey | (customer_id) REFERENCES customers(id) ON DELETE CASCADE
# ----------------------------------------------------------------------------------------------
