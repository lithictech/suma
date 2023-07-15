# frozen_string_literal: true

require "sequel"

module Sequel
  def self.null_or_present_constraint(col)
    return (Sequel[col] =~ nil) | (Sequel[col] !~ "")
  end
end
