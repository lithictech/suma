# frozen_string_literal: true

require "suma/eligibility"
require "suma/has_activity_audit"
require "suma/postgres/model"

class Suma::Eligibility::Attribute < Suma::Postgres::Model(:eligibility_attributes)
  include Suma::AdminLinked
  include Suma::HasActivityAudit
  include Suma::Postgres::HybridSearch

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :parent, class: self
  one_to_many :assignments, class: "Suma::Eligibility::Assignment"
  one_to_many :referenced_requirements,
              class: "Suma::Eligibility::Requirement",
              dataset: lambda {
                Suma::Eligibility::Requirement.where(Sequel.pg_array(:cached_attribute_ids).contains([id]))
              },
              eager_loader: (lambda do |eo|
                id_map = {}
                eo[:rows].each do |parent|
                  parent.associations[:referenced_requirements] = []
                  id_map[parent.id] = parent
                end

                ds = Suma::Eligibility::Requirement.
                  where(Sequel.pg_array(:cached_attribute_ids).overlaps(id_map.keys))
                ds.all do |child|
                  child.cached_attribute_ids.each do |parent_id|
                    if (parent = id_map[parent_id])
                      parent.associations[:referenced_requirements] << child
                    end
                  end
                end
              end)

  class << self
    # Given a collection of attributes, accumulate all parents.
    # @return [Sequel::IdentitySet,Set<Suma::Eligibility::Attribute>]
    def accumulate(attrs, accum: Sequel::IdentitySet.new)
      attrs.each do |a|
        accum << a
        self.accumulate([a.parent], accum:) if a.parent
      end
      return accum
    end
  end

  def rel_admin_link = "/eligibility-attribute/#{self.id}"
end
