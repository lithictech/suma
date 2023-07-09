# frozen_string_literal: true

Sequel.migration do
  change do
    create_join_table(
      {constraint_id: :eligibility_constraints, service_id: :vendor_services},
      name: :eligibility_vendor_service_associations,
    )

    create_join_table(
      {constraint_id: :eligibility_constraints, configuration_id: :anon_proxy_vendor_configurations},
      name: :eligibility_anon_proxy_vendor_configuration_associations,
    )
  end
end
