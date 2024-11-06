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
    # Limit the dataset to rows which are related to rows which have no program,
    # or have a program overlapping with the member's active program enrollments.
    def eligible_to(member, as_of:)
      unconstrained = Sequel.~(programs: Suma::Program.dataset)
      # member_program_ids = Suma::Member.member.active_program_enrollments_dataset.select(:program_id)
      # ds = self.where(unconstrained | Sequel[programs: Suma::Program.where(id: member_program_ids)])
      ds = self.where(
        unconstrained |
          Sequel[program_enrollments: member.combined_program_enrollments_dataset.active(as_of:)]
      )
      return ds
    end
  end

  module InstanceMethods
    def eligible_to?(member, as_of:)
      # return !self.class.eligible_to(member, as_of:).where(id: self.id).empty?
      return !self.program_enrollments_dataset.active(as_of:).for_members(member).empty?
    end
  end
end
