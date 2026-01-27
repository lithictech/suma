# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::MemberAssignment < Suma::Postgres::Model(:eligibility_member_assignments)
  many_to_one :attribute, class: "Suma::Eligibility::Attribute"
  many_to_one :member, class: "Suma::Member"
end
