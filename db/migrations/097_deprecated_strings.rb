# frozen_string_literal: true

require "sequel/all_or_none_constraint"

Sequel.migration do
  up do
    # Clean up these tables we have lying around.
    drop_table?(:eligibility_member_associations)
    drop_table?(:eligibility_anon_proxy_vendor_configuration_associations)
    drop_table?(:eligibility_offering_associations)
    drop_table?(:eligibility_payment_trigger_associations)
    drop_table?(:eligibility_vendor_service_associations)
    drop_table?(:eligibility_constraints)

    alter_table(:i18n_static_strings) do
      add_column :deprecated_at, :timestamptz
    end
    from(:i18n_static_strings).where(deprecated: true).update(deprecated_at: Time.now)
    alter_table(:i18n_static_strings) do
      drop_column :deprecated
    end
  end

  down do
    alter_table(:i18n_static_strings) do
      add_column :deprecated, :boolean, default: false, null: false
    end
    from(:i18n_static_strings).exclude(deprecated_at: nil).update(deprecated: true)
    alter_table(:i18n_static_strings) do
      drop_column :deprecated_at
    end
  end
end
