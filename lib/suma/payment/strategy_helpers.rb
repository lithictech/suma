# frozen_string_literal: true

module Suma::Payment::StrategyHelpers
  def admin_details_typed
    d = self.admin_details
    r = d.map do |label, value|
      type = case value
        when Hash, Array
          :json
        when Time
          :time
        when Numeric
          :numeric
        else
          :string
      end
      {label:, type:, value:}
    end
    r.sort_by! { |o| o[:label] }
    r.unshift({label: "Strategy", type: :string, value: self.short_name})
    return r
  end
end
