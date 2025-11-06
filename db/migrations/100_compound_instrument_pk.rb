# frozen_string_literal: true

Sequel.migration do
  up do
    now = Sequel.function(:now)
    drop_view :payment_instruments
    create_view :payment_instruments,
                from(:payment_bank_accounts).
                  left_join(
                    from(:plaid_institutions).select(Sequel[:pk].as(:plaid_pk), Sequel[:name].as(:plaid_name)),
                    {plaid_pk: :plaid_institution_id},
                  ).select(
                    Sequel.function(:concat, "ba", :id).as(:pk),
                    Sequel[:id].as(:instrument_id),
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
                        Sequel.function(:concat, "cr", :id).as(:pk),
                        Sequel[:id].as(:instrument_id),
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
    create_view :payment_instruments,
                from(:payment_bank_accounts).
                  select(:id, Sequel.as("bank_account", :type)).
                  union(
                    from(:payment_cards).select(:id, Sequel.as("card", :type)),
                  )
  end
end
