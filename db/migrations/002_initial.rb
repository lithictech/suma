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

      citext :email, null: false, unique: true
      constraint(:lowercase_nospace_email, Sequel[:email] => Sequel.function(:btrim, Sequel.function(:lower, :email)))
      timestamptz :email_verified_at

      text :phone, null: false, unique: true
      constraint(:numeric_phone, Sequel.lit("phone ~ '^[0-9]{11,15}$'"))
      timestamptz :phone_verified_at

      text :name, null: false, default: ""
      text :note, null: false, default: ""
      text :timezone, null: false, default: "America/Los_Angeles"
      text :registered_env, null: false

      foreign_key :legal_entity_id, :legal_entities, null: false
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
  end
end
