# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:supported_geographies) do
      primary_key :id
      citext :label, null: false
      citext :value, null: false
      text :type, null: false
      constraint(:valid_type, Sequel[:type] => ["province", "country"])
      foreign_key :parent_id, :supported_geographies, on_delete: :cascade
      constraint(:valid_type_settings,
                 Sequel.lit("(type = 'country' AND parent_id IS NULL) " \
                            "OR (type = 'province' AND parent_id IS NOT NULL)"),)

      unique [:value, :parent_id], name: :unique_child_values
      unique [:label, :parent_id], name: :unique_child_labels
    end

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

    create_table(:plaid_institutions) do
      primary_key :pk
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :institution_id, null: false, unique: true
      text :name, null: false
      text :logo_base64, null: false, default: ""
      text :primary_color_hex, null: false, default: "#000000"
      column :routing_numbers, "text[]", null: false
      index :routing_numbers, type: :GIN
      jsonb :data, null: false, default: "{}"
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

      timestamptz :onboarding_verified_at, null: true

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

      foreign_key :customer_id, :customers, null: false, on_delete: :cascade, index: true
    end

    create_join_table({role_id: :roles, customer_id: :customers}, name: :roles_customers)

    create_table(:customer_activities) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :message_name, null: false
      jsonb :message_vars, null: false, default: "{}"
      text :summary, null: false
      text :subject_type, null: false
      text :subject_id, null: false

      foreign_key :customer_id, :customers, null: false, on_delete: :cascade, index: true
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
      foreign_key :recipient_id, :customers, on_delete: :set_null, index: true
      jsonb :extra_fields, null: false, default: "{}"
      timestamptz :sent_at
      index :sent_at
      timestamptz :aborted_at
    end

    create_table(:message_bodies) do
      primary_key :id
      text :content, null: false
      text :mediatype, null: false
      foreign_key :delivery_id, :message_deliveries, null: false, on_delete: :cascade, index: true
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
      foreign_key :organization_id, :organizations, null: false, on_delete: :cascade, index: true
    end

    create_table(:vendor_services) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :vendor_id, :vendors, null: false, on_delete: :cascade, index: true

      text :internal_name, null: false
      text :external_name, null: false
      text :sync_url, null: false, default: ""

      text :mobility_vendor_adapter_key, null: false, default: ""
    end

    create_table(:vendor_service_categories) do
      primary_key :id
      text :name, null: false
      text :slug, null: false, unique: true
      foreign_key :parent_id, :vendor_service_categories, index: true
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

      foreign_key :vendor_service_id, :vendor_services, null: false, on_delete: :cascade, index: true
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

      foreign_key :undiscounted_rate_id, :vendor_service_rates, index: true

      text :localization_key, null: false
      text :name, null: false
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

      foreign_key :customer_id, :customers, null: false, index: true

      index :customer_id, name: "one_active_ride_per_customer", unique: true, where: Sequel[ended_at: nil]
      constraint(
        :end_fields_set_together,
        Sequel.lit("(end_lat IS NULL AND end_lng IS NULL AND ended_at IS NULL) OR " \
                   "(end_lat IS NOT NULL AND end_lng IS NOT NULL AND ended_at IS NOT NULL)"),
      )
    end

    create_table(:bank_accounts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at
      timestamptz :verified_at

      text :routing_number, null: false
      text :account_number, null: false

      foreign_key :legal_entity_id, :legal_entities, null: false, on_delete: :restrict
      foreign_key :plaid_institution_id, :plaid_institutions, on_delete: :set_null

      text :name, null: false
      text :account_type, null: false

      index [:legal_entity_id, :routing_number, :account_number],
            name: :undeleted_legal_entity_id_routing_number_account_number_key,
            unique: true,
            where: Sequel[soft_deleted_at: nil]
    end

    create_table(:payment_accounts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :customer_id, :customers, null: true, unique: true
      foreign_key :vendor_id, :vendors, null: true, unique: true
      boolean :is_platform_account, null: false, default: false
      index [:is_platform_account],
            name: :one_platform_account,
            unique: true,
            where: Sequel[is_platform_account: true]

      constraint(
        :unambiguous_owner,
        Sequel.lit(
          "(customer_id IS NOT NULL AND vendor_id IS NULL) " \
          "OR (customer_id IS NULL AND vendor_id IS NOT NULL) " \
          "OR (is_platform_account IS TRUE AND customer_id IS NULL AND vendor_id IS NULL)",
        ),
      )
    end

    create_table(:payment_ledgers) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :currency, null: false

      foreign_key :account_id, :payment_accounts, index: true
    end

    create_join_table(
      {
        category_id: :vendor_service_categories,
        ledger_id: :payment_ledgers,
      },
      name: :vendor_service_categories_payment_ledgers,
    )

    create_table(:payment_book_transactions) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :originating_ledger_id, :payment_ledgers, index: true
      foreign_key :receiving_ledger_id, :payment_ledgers, index: true
      foreign_key :associated_vendor_service_category_id, :vendor_service_categories

      int :amount_cents, null: false
      text :amount_currency, null: false
      constraint(:amount_not_negative, Sequel.lit("amount_cents >= 0"))

      text :memo, null: false
    end

    create_table(:payment_fake_strategies) do
      primary_key :id
      jsonb :responses, null: false, default: "{}"
    end

    create_table(:payment_funding_transaction_increase_ach_strategies) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :originating_bank_account_id, :bank_accounts, null: false
      jsonb :ach_transfer_json, null: false, default: "{}"
      jsonb :transaction_json, null: false, default: "{}"
    end

    create_table(:payment_funding_transactions) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :status, null: false
      int :amount_cents, null: false
      text :amount_currency, null: false
      constraint(:amount_positive, Sequel.lit("amount_cents > 0"))
      text :memo, null: false

      foreign_key :originating_payment_account_id, :payment_accounts, null: false, index: true, on_delete: :restrict
      foreign_key :platform_ledger_id, :payment_ledgers, null: false, index: true, on_delete: :restrict
      foreign_key :originated_book_transaction_id, :payment_book_transactions,
                  null: true, unique: true, on_delete: :restrict

      foreign_key :fake_strategy_id, :payment_fake_strategies,
                  null: true, unique: true
      foreign_key :increase_ach_strategy_id, :payment_funding_transaction_increase_ach_strategies,
                  null: true, unique: true
      constraint(
        :unambiguous_strategy,
        Sequel.lit(
          "(fake_strategy_id IS NOT NULL AND increase_ach_strategy_id IS NULL) OR" \
          "(fake_strategy_id IS NULL AND increase_ach_strategy_id IS NOT NULL)",
        ),
      )
    end

    create_table(:payment_funding_transaction_audit_logs) do
      primary_key :id
      timestamptz :at, null: false

      text :event, null: false
      text :to_state, null: false
      text :from_state, null: false
      text :reason, null: false, default: ""
      jsonb :messages, default: "[]"

      foreign_key :funding_transaction_id, :payment_funding_transactions, null: false
      foreign_key :actor_id, :customers, on_delete: :set_null
    end

    create_table(:charges) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      int :undiscounted_subtotal_cents, null: false
      text :undiscounted_subtotal_currency, null: false

      foreign_key :customer_id, :customers, null: false
      index :customer_id

      foreign_key :mobility_trip_id, :mobility_trips, null: true, on_delete: :set_null, index: true
    end

    create_join_table(
      {charge_id: :charges, book_transaction_id: :payment_book_transactions},
      name: :charges_payment_book_transactions,
    )
  end
end
