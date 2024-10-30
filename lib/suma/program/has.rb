# frozen_string_literal: true

require "suma/program"

module Suma::Program::Has
  # @!attribute programs
  # @return [Array<Suma::Program>]

  def self.included(mod)
    raise TypeError, "#{mod} must define a :programs method or association" unless
      mod.instance_methods.include?(:programs)
    mod.dataset_module DatasetMethods
    mod.include InstanceMethods
  end

  module DatasetMethods
    def eligible_to(member, as_of:)
      # Include all rows that have no programs
      unconstrained = Sequel.~(programs: Suma::Program.dataset)
      if member.program_enrollments_dataset.active(as_of:).empty?
        # If the member has no constraints, return all offerings that also have no constraints.
        return self.where(unconstrained)
      end
      # Include all rows where the member has overlapping programs.
      member_programs = member.program_enrollments_dataset.active(as_of:)
      overlapping = Sequel[programs: Suma::Program.where(id: member_programs.select(:program_id))]
      ds = self.where(unconstrained | overlapping)
      puts ds.sql
      return ds
    end
  end

  module InstanceMethods
    def eligible_to?(member, as_of:)
      programs = self.programs_dataset.active(as_of:).all
      return true if programs.empty?
      return programs.any? { |p| p.enrollment_for(member, as_of:) }
    end
  end
end
