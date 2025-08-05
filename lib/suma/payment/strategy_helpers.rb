# frozen_string_literal: true

module Suma::Payment::StrategyHelpers
  def admin_details_typed
    d = self.admin_details
    model_label_attrs = [:admin_label, :search_label, :name].freeze
    r = d.map do |label, value|
      type = case value
        when Hash, Array, Sequel::Postgres::JSONBObject
          :json
        when Time
          :date
        when Numeric
          :numeric
        when Sequel::Model
          m = model_label_attrs.find { |m| value.respond_to?(m) }
          model_label = m ? value.send(m) : "#{value.class}[#{value.pk}]"
          value = {
            label: model_label,
            link: value.respond_to?(:admin_link) ? value.admin_link : nil,
          }
          :model
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
