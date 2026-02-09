# frozen_string_literal: true

require "suma/program"

module Suma::Program::Has
  def self.configure(model, join_table, left_key)
    require "suma/program"

    model.many_to_many :programs,
                       class: "Suma::Program",
                       join_table:,
                       left_key:,
                       order: Suma::Postgres::Model.order_desc
  end

  module InstanceMethods
    def eligible_to?(member, as_of:)
      return true if self.programs.empty? && Suma::Eligibility::RESOURCES_DEFAULT_ACCESSIBLE
      return self.programs.any? { |p| p.eligible_to?(member, as_of:) }
    end
  end
end
