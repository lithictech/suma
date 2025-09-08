# frozen_string_literal: true

module Sequel::Plugins::GeneratedColumns
  def self.apply(model)
    model.plugin :skip_saving_columns
  end

  def self.configure(model)
    model.db_schema&.each do |col, schema|
      next unless schema[:generated]
      model.instance_eval do
        undef_method "#{col}="
      end
    end
  end
end
