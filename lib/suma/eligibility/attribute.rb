# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Attribute < Suma::Postgres::Model(:eligibility_attributes)
  many_to_one :parent, class: self

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
end
