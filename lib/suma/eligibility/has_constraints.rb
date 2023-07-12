# frozen_string_literal: true

require "suma/eligibility"

require "sequel"

module Suma::Eligibility::HasConstraints
  # @!attribute eligibility_constraints
  # @return [Array<Suma::Eligibility::Constraint>]

  def self.included(mod)
    raise TypeError, "#{mod} must define a vendor_service_categories method or association" unless
      mod.instance_methods.include?(:eligibility_constraints)
    mod.dataset_module DatasetMethods
    mod.include InstanceMethods
  end

  module DatasetMethods
    def eligible_to(member)
      # First select all rows that have no constraints
      unconstrained = Sequel.~(eligibility_constraints: Suma::Eligibility::Constraint.dataset)
      if member.verified_eligibility_constraints.empty?
        # If the member has no constraints, return all offerings that also have no constraints.
        return self.where(unconstrained)
      end
      # Include all rows where the member has overlapping constraints.
      overlapping = Sequel[eligibility_constraints: member.verified_eligibility_constraints_dataset]
      return self.where(unconstrained | overlapping)
    end
  end

  module InstanceMethods
    def eligible_to?(member)
      return true if self.eligibility_constraints.empty?
      member_ids = member.verified_eligibility_constraints.map(&:id).to_set
      return self.eligibility_constraints.any? { |ec| member_ids.include?(ec.id) }
    end
  end
end
