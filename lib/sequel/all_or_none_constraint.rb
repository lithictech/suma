# frozen_string_literal: true

require "sequel"

module Sequel
  def self.all_or_none_constraint(cols)
    raise ArgumentError, "cols cannot be empty" if cols.empty?
    all_nil = cols.map { |c| Sequel[c] =~ nil }.reduce(&:&)
    none_nil = cols.map { |c| Sequel[c] !~ nil }.reduce(&:&)
    return all_nil | none_nil
  end
end
