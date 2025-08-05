# frozen_string_literal: true

module Suma::Payment::StrategyHelpers
  def admin_details_typed
    d = self.admin_details
    r = d.map do |label, value|
      type = case value
        when Hash, Array, Sequel::Postgres::JSONBObject
          :json
        when Time
          :date
        when Numeric
          :numeric
        else
          /^http/.match?(value) ? :href : :string
      end
      {label:, type:, value:}
    end
    r.sort_by! { |o| o[:label] }
    r.unshift({label: "Type", type: :string, value: self.short_name})
    return r
  end
end
