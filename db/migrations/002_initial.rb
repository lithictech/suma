# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:addresses) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      citext :address1, null: false
      citext :address2, null: false, default: ""
      citext :city, null: false
      citext :state_or_province, null: false
      citext :postal_code, null: false
      citext :country, null: false, default: "US"

      float :lat
      float :lng
      column :suggested_bounds_nesw, "float[]"

      jsonb :geocoder_data, null: false, default: "{}"
      text :geocoded_address, null: false, default: ""

      unique [:address1, :address2, :postal_code]
    end

    create_table(:legal_entities) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at

      text :name, null: false, default: ""
      foreign_key :address_id, :addresses, on_delete: :set_null
    end

    create_table(:idempotencies) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :last_run
      text :key, unique: true
    end

    create_table(:roles) do
      primary_key :id
      text :name, null: false, unique: true
    end

    create_table(:customers) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at

      text :password_digest, null: false
      text :opaque_id, null: false

      citext :email, null: true, unique: true
      constraint(
        :lowercase_nospace_email,
        Sequel[:email] => Sequel.function(:btrim, Sequel.function(:lower, :email)),
      )
      constraint(
        :email_present,
        Sequel[email: nil] | (Sequel.function(:length, :email) > 0),
      )

      text :phone, null: false, unique: true
      constraint(:numeric_phone, Sequel.lit("phone ~ '^[0-9]{11,15}$'"))

      text :name, null: false, default: ""
      text :note, null: false, default: ""
      text :timezone, null: false, default: "America/Los_Angeles"
      text :registered_env, null: false

      foreign_key :legal_entity_id, :legal_entities, null: false, on_delete: :restrict
    end

    create_join_table(
      {customer_id: :customers, linked_legal_entity_id: :legal_entities},
      name: :customer_linked_legal_entities,
    )

    create_table(:customer_reset_codes) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :transport, null: false
      text :token, null: false
      boolean :used, null: false, default: false
      timestamptz :expire_at, null: false

      foreign_key :customer_id, :customers, null: false, on_delete: :cascade
      index :customer_id
    end

    create_join_table({role_id: :roles, customer_id: :customers}, name: :roles_customers)

    create_table(:customer_journeys) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :processed_at

      text :name, null: false
      text :subject_type, null: false
      text :subject_id, null: false
      text :disambiguator, null: false, default: ""
      index [:name, :subject_type, :subject_id, :disambiguator],
            name: :customer_journeys_uniqueness_index,
            unique: true

      text :message, null: false

      foreign_key :customer_id, :customers, null: false, on_delete: :cascade
      index :customer_id
    end

    create_table(:customer_sessions) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)

      foreign_key :customer_id, :customers, null: false, on_delete: :cascade
      text :user_agent, null: false
      inet :peer_ip, null: false

      index :peer_ip
      index :user_agent
      index :customer_id
    end

    create_table(:message_deliveries) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      text :template, null: false
      text :transport_type, null: false
      text :transport_service, null: false
      text :transport_message_id, unique: true
      text :to, null: false
      foreign_key :recipient_id, :customers, on_delete: :set_null
      index :recipient_id
      jsonb :extra_fields, null: false, default: "{}"
      timestamptz :sent_at
      index :sent_at
      timestamptz :aborted_at
    end

    create_table(:message_bodies) do
      primary_key :id
      text :content, null: false
      text :mediatype, null: false
      foreign_key :delivery_id, :message_deliveries, null: false, on_delete: :cascade
      index :delivery_id
    end

    create_table(:organizations) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      text :name, null: false
      text :slug, null: false
    end

    create_table(:markets) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      text :name, null: false
      text :slug, null: false
    end

    create_table(:vendors) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      text :name, null: false
      text :slug, null: false
      foreign_key :organization_id, :organizations, null: false, on_delete: :cascade
    end

    create_table(:vendor_services) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :vendor_id, :vendors, null: false, on_delete: :cascade

      text :internal_name, null: false
      text :external_name, null: false
      text :sync_url, null: false, default: ""

      text :mobility_vendor_adapter_key, null: false, default: ""
    end

    create_table(:vendor_service_categories) do
      primary_key :id
      text :name, null: false
      text :slug, null: false, unique: true
    end

    create_join_table(
      {
        category_id: :vendor_service_categories,
        service_id: :vendor_services,
      },
      name: :vendor_service_categories_vendor_services,
    )

    create_table(:vendor_service_market_constraints) do
      primary_key :id
      foreign_key :service_id, :vendor_services, null: false, on_delete: :cascade
      foreign_key :market_id, :markets, null: false, on_delete: :cascade
      unique [:service_id, :market_id]
    end

    create_table(:vendor_service_organization_constraints) do
      primary_key :id
      foreign_key :service_id, :vendor_services, null: false, on_delete: :cascade
      foreign_key :organization_id, :organizations, null: false, on_delete: :cascade
      unique [:service_id, :organization_id]
    end

    create_table(:vendor_service_role_constraints) do
      primary_key :id
      foreign_key :service_id, :vendor_services, null: false, on_delete: :cascade
      foreign_key :role_id, :roles, null: false, on_delete: :cascade
      unique [:service_id, :role_id]
    end

    create_table(:vendor_service_matchall_constraints) do
      primary_key :id
      foreign_key :service_id, :vendor_services, null: false, on_delete: :cascade
      unique :service_id
    end

    create_table(:mobility_vehicles) do
      primary_key :id
      decimal :lat, null: false
      decimal :lng, null: false
      text :vehicle_type, null: false
      text :vehicle_id, null: false

      foreign_key :vendor_service_id, :vendor_services, null: false, on_delete: :cascade
      index :vendor_service_id
    end

    create_table(:vendor_service_rates) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      int :unit_amount_cents, null: false
      text :unit_amount_currency, null: false
      int :surcharge_cents, null: false
      text :surcharge_currency, null: false
      int :unit_offset, null: false, default: 0

      foreign_key :undiscounted_rate_id, :vendor_service_rates
      index :undiscounted_rate_id
    end

    create_join_table(
      {vendor_service_id: :vendor_services, vendor_service_rate_id: :vendor_service_rates},
      name: :vendor_service_vendor_service_rates,
    )

    create_table(:mobility_trips) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      # We CANNOT use an FK into vehicles, because they are ephemeral
      text :vehicle_id, null: false
      foreign_key :vendor_service_id, :vendor_services, null: false, on_delete: :restrict
      index [:vehicle_id, :vendor_service_id]

      numeric :begin_lat, null: false
      numeric :begin_lng, null: false
      timestamptz :began_at, null: false
      numeric :end_lat, null: true
      numeric :end_lng, null: true
      timestamptz :ended_at, null: true

      foreign_key :vendor_service_rate_id, :vendor_service_rates, null: false, on_delete: :restrict

      foreign_key :customer_id, :customers, null: false
      index :customer_id

      index :customer_id, name: "one_active_ride_per_customer", unique: true, where: Sequel[ended_at: nil]
      constraint(
        :end_fields_set_together,
        Sequel.lit("(end_lat IS NULL AND end_lng IS NULL AND ended_at IS NULL) OR " \
                   "(end_lat IS NOT NULL AND end_lng IS NOT NULL AND ended_at IS NOT NULL)"),
      )
    end

    create_table(:charges) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      int :undiscounted_subtotal_cents, null: false
      text :undiscounted_subtotal_currency, null: false
      int :discounted_subtotal_cents, null: false
      text :discounted_subtotal_currency, null: false

      foreign_key :customer_id, :customers, null: false
      index :customer_id

      foreign_key :mobility_trip_id, :mobility_trips, null: true, on_delete: :set_null
      unique :mobility_trip_id
    end
  end
end
