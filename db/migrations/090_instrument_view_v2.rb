# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:payment_cards) do
      getyear = Sequel.pg_jsonb(:stripe_json).get_text("exp_year").cast(:integer)
      getmo = Sequel.pg_jsonb(:stripe_json).get_text("exp_month").cast(:integer)
      add_column :expires_at,
                 :timestamptz,
                 # We need to use timezone('UTC', make_timestamp(y, m, 1) + 1 month)
                 # (that is, add the month to the timestamp first) because `timestamptz + interval` is stable,
                 # but `timestamp + interval` is immutable. And we need to use immutable functions here.
                 generated_always_as: Sequel.function(
                   :timezone,
                   "UTC",
                   Sequel.function(:make_timestamp, getyear, getmo, 1, 0, 0, 0) +
                   Sequel["1 month"].cast(:interval),
                 )
      add_column :last4,
                 :text,
                 generated_always_as: Sequel.pg_jsonb(:stripe_json).get_text("last4")
      add_column :brand,
                 :text,
                 generated_always_as: Sequel.pg_jsonb(:stripe_json).get_text("brand")
      add_column :name,
                 :text,
                 generated_always_as: Sequel.pg_jsonb(:stripe_json).get_text("brand") +
                   " x-" +
                   Sequel.pg_jsonb(:stripe_json).get_text("last4")
    end

    now = Sequel.function(:now)
    drop_view :payment_instruments
    create_view :payment_instruments,
                from(:payment_bank_accounts).
                  left_join(
                    from(:plaid_institutions).select(Sequel[:pk].as(:plaid_pk), Sequel[:name].as(:plaid_name)),
                    {plaid_pk: :plaid_institution_id},
                  ).select(
                    :id,
                    Sequel.as("bank_account", :payment_method_type),
                    :name,
                    Sequel.function(:coalesce, Sequel[:plaid_name], "Unknown").as(:institution_name),
                    :legal_entity_id,
                    (Sequel[:verified_at] !~ nil).as(:usable_for_funding),
                    Sequel[true].as(:usable_for_payout),
                    Sequel[nil].as(:expires_at),
                    (Sequel[:verified_at] !~ nil).as(:verified),
                    :soft_deleted_at,
                    :search_content, :search_embedding, :search_hash,
                  ).
                  union(
                    from(:payment_cards).
                      select(
                        :id,
                        Sequel.as("card", :payment_method_type),
                        :name,
                        Sequel[:brand].as(:institution_name),
                        :legal_entity_id,
                        (Sequel[:expires_at] > now).as(:usable_for_funding),
                        Sequel[false].as(:usable_for_payout),
                        :expires_at,
                        Sequel[true].as(:verified),
                        :soft_deleted_at,
                        :search_content, :search_embedding, :search_hash,
                      ),
                  )
  end
  down do
    drop_view :payment_instruments
    common_columns = [:id, :soft_deleted_at, :search_content, :search_embedding, :search_hash]
    create_view :payment_instruments,
                from(:payment_bank_accounts).
                  select(*common_columns, Sequel.as("bank_account", :type)).
                  union(
                    from(:payment_cards).select(*common_columns, Sequel.as("card", :type)),
                  )
    alter_table(:payment_cards) do
      drop_column :expires_at
      drop_column :last4
      drop_column :brand
      drop_column :name
    end
  end
end
