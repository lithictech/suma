# frozen_string_literal: true

Sequel.migration do
  up do
    ["upload_files", "admin", "onboarding_manager", "admin_readonly"].each do |name|
      from(:roles).
        insert_conflict.
        insert(name:)
    end
  end
end
