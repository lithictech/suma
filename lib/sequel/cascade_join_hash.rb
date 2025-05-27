# frozen_string_literal: true

require "sequel"

module Sequel
  # Standard join table criteria uses default of ON DELETE RESTRICT.
  # Tell Sequel to use ON DELETE CASCADE instead.
  def self.cascade_join_hash(h, on_delete: :cascade)
    return h.transform_values do |v|
      {table: v, on_delete:}
    end
  end
end
