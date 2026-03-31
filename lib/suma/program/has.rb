# frozen_string_literal: true

require "suma/program"

module Suma::Program::Has
  def self.configure(model, join_table, left_key, &)
    require "suma/program"

    if block_given?
      model.define_method(:programs, &)
    else
      model.many_to_many :programs,
                         class: "Suma::Program",
                         join_table:,
                         left_key:,
                         order: Suma::Postgres::Model.order_desc
    end
  end

  module DatasetMethods
    # See +Suma::Eligibility::Resource::DatasetMethods.fetch_eligible_to+
    # for info.
    def fetch_eligible_to(member, as_of:)
      rows = self.all.select do |receiver|
        receiver.eligible_to?(member, as_of:)
      end
      return rows
    end
  end

  module InstanceMethods
    def programs_eligible_to(member, as_of:)
      return self.programs.select { |p| p.eligible_to?(member, as_of:) }
    end

    def eligible_to?(member, as_of:)
      return true if self.programs.empty? && Suma::Eligibility::RESOURCES_DEFAULT_ACCESSIBLE
      return self.programs_eligible_to(member, as_of:).any?
    end
  end
end
