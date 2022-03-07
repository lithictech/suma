# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Role < Suma::Postgres::Model(:roles)
  def self.admin_role
    return Suma.cached_get("role_admin") do
      self.find_or_create_or_find(name: "admin")
    end
  end

  many_to_many :customers,
               class: "Suma::Customer",
               join_table: :roles_customers
end
