# frozen_string_literal: true

require "sequel"

module Sequel
  def self.not_self_constraint(c, pk=:id)
    return (Sequel[c] =~ nil) | (Sequel[c] !~ pk)
  end
end
