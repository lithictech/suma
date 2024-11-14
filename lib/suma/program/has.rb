# frozen_string_literal: true

require "suma/program"

module Suma::Program::Has
  # @!attribute programs
  # @return [Array<Suma::Program>]

  def self.included(mod)
    raise TypeError, "#{mod} must define a :programs method or association" unless
      mod.instance_methods.include?(:programs)
    mod.dataset_module DatasetMethods

    assoc = mod.association_reflections[:programs]
    mod.many_through_many :program_enrollments,
                          [
                            [assoc[:join_table], assoc[:left_key], :program_id],
                          ],
                          class: "Suma::Program::Enrollment",
                          left_primary_key: :id,
                          right_primary_key: :program_id,
                          read_only: true
    mod.include InstanceMethods
  end

  module DatasetMethods
    def eligible_to(member, as_of:)
      # Include all rows that have no programs
      unconstrained = Sequel.~(programs: Suma::Program.dataset)
      ds = self.where(
        unconstrained |
        Sequel[program_enrollments: member.combined_program_enrollments_dataset.active(as_of:)],
      )
      return ds
    end
  end

  module InstanceMethods
    def eligible_to?(member, as_of:)
      return !self.class.where(id: self.id).eligible_to(member, as_of:).empty?
    end
  end
end
