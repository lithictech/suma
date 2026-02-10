# frozen_string_literal: true

require "suma/eligibility"

# Sequel plugin for eligibility resources (things which have requirements,
# ie is one of +Suma::Eligibility::Requirement::RESOURCE_ASSOCIATIONS+).
# Include this after defining the :eligibility_requirements association.
module Suma::Eligibility::Resource
  DEFAULT_OPTIONS = {
    association: :eligibility_requirements,
    key: nil,
    period: :period,
  }.freeze

  def self.configure(model, **opts)
    require "suma/eligibility/requirement"

    reverse = Suma::Eligibility::Requirement.association_reflections.each_value.find { |v| v[:class_name] == model.name }
    opts = DEFAULT_OPTIONS.merge(opts, reverse:)
    model.eligibility_resource_plugin_options = opts
    model.one_to_many opts[:association],
                      key: opts[:key],
                      class: "Suma::Eligibility::Requirement",
                      order: Suma::Postgres::Model.order_desc
  end

  module ClassMethods
    attr_accessor :eligibility_resource_plugin_options
  end

  module DatasetMethods
    # Return all rows actually eligible to the member.
    # This method combines +active+, +potentially_eligible_to+, and +evaluate_eligible_to+
    # into one easy method.
    def fetch_eligible_to(member, as_of:)
      ds = self
      ds = ds.active_at(as_of)
      ds = ds.potentially_eligible_to(member)
      rows = ds.evaluate_eligible_to(member)
      return rows
    end

    # Limit the dataset to rows where as_of is within the period.
    def active_at(as_of)
      pcol = self.model.eligibility_resource_plugin_options[:period]
      return self.where { (lower(pcol) <= as_of) & (upper(pcol) > as_of) }
    end

    # Rows that are potentially eligible are those which have an attribute in their expression
    # which overlaps with one of the attributes a member has through some assignment (direct, role, etc).
    def potentially_eligible_to(_m)
      return self if Suma::Eligibility::RESOURCES_DEFAULT_ACCESSIBLE
      # TODO: Just return all rows for now. Performance won't be great,
      # but it's okay for now, and we may figure out a better model.
      return self
    end

    # Select all rows, and return only those which are eligible to the member.
    # Generally callers should use +fetch_eligible_to+.
    def evaluate_eligible_to(member)
      rows = self.all
      if Suma::Eligibility::RESOURCES_DEFAULT_ACCESSIBLE
        rows.select! do |r|
          # Allow things that pass or are empty.
          # Make the 'if' check outside the block so we don't run it for every row.
          r.eligibility_requirements.empty? || Suma::Eligibility::Evaluation.evaluate(member, r).access?
        end
      else
        rows.select! { |r| Suma::Eligibility::Evaluation.evaluate(member, r).access? }
      end
      return rows
    end
  end

  module InstanceMethods
    def eligible_to?(member, as_of:)
      return false unless self.send(self.class.eligibility_resource_plugin_options.fetch(:period)).cover?(as_of)
      return Suma::Eligibility::Evaluation.evaluate(member, self).access?
    end

    def requirement_where_condition
      assoc = self.class.eligibility_resource_plugin_options.fetch(:reverse)
      return {assoc.fetch(:key) => self.pk}
    end
  end
end
