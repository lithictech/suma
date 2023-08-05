# frozen_string_literal: true

Sequel.migration do
  up do
    drop_table?(:markets)
  end
  down do
  end
end
