# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Assignment < Suma::Postgres::Model(:eligibility_assignments)
  many_to_one :attribute, class: "Suma::Eligibility::Attribute"

  many_to_one :member, class: "Suma::Member"
  many_to_one :organization, class: "Suma::Organization"
  many_to_one :role, class: "Suma::Role"

  ASSIGNEE_ASSOCIATIONS = [:member, :organization, :role].freeze

  def assignee = Suma::MethodUtilities.unambiguous_association(self, ASSIGNEE_ASSOCIATIONS)

  def assignee=(o)
    Suma::MethodUtilities.set_ambiguous_association(self, ASSIGNEE_ASSOCIATIONS, o)
  end
end
