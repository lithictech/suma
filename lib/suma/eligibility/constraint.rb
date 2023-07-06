# frozen_string_literal: true

require "suma/postgres/model"

require "suma/eligibility"

class Suma::Eligibility::Constraint < Suma::Postgres::Model(:eligibility_constraints)
  STATUSES = ["pending", "verified", "rejected"].freeze

  plugin :timestamps
end
