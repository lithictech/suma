# frozen_string_literal: true

require "sequel"

module Sequel
  def self.nonempty_string_constraint(col)
    return (Sequel[col] !~ nil) & (Sequel[col] !~ "")
  end
end
