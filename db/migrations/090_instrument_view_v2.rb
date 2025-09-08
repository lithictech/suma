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
    end

    now = Sequel.function(:now)
    common_columns = [:id, :soft_deleted_at, :search_content, :search_embedding, :search_hash]
    drop_view :payment_instruments
    create_view :payment_instruments,
                from(:payment_bank_accounts).
                  select(*common_columns,
                         (Sequel[:verified_at] !~ nil).as(:usable_for_funding),
                         Sequel[true].as(:usable_for_payout),
                         Sequel.as("bank_account", :type),).
                  union(
                    from(:payment_cards).
                      select(*common_columns,
                             (Sequel[:expires_at] > now).as(:usable_for_funding),
                             Sequel[false].as(:usable_for_payout),
                             Sequel.as("card", :type),),
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
  end
end
