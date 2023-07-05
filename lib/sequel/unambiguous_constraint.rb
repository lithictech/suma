# frozen_string_literal: true

require "sequel"

module Sequel
  def self.unambiguous_constraint(columns, allow_all_null: false, compare_to: nil)
    raise ArgumentError, "must provide at least one column" if columns.empty?
    lines = columns.map do |outer_col|
      conds = columns.map do |inner_col|
        outer_col == inner_col ? Sequel[inner_col] !~ compare_to : Sequel[inner_col] =~ compare_to
      end
      conds[1..].inject(conds.first) { |memo, expr| memo & expr }
    end
    lines << columns[1..].inject(Sequel[columns.first] =~ nil) { |memo, c| memo & (Sequel[c] =~ nil) } if
      allow_all_null
    return lines[1..].inject(lines.first) { |memo, expr| memo | expr }
  end

  def self.unambiguous_bool_constraint(columns, allow_all_null: false)
    return self.unambiguous_constraint(columns, allow_all_null:, compare_to: false)
  end
end
