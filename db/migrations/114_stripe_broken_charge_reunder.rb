# frozen_string_literal: true

Sequel.migration do
  up do
    if ENV["RACK_ENV"] == "test"
      run <<~SQL
        CREATE TABLE stripe_charge_v1_fixture (
          pk bigserial PRIMARY KEY,
          stripe_id text UNIQUE NOT NULL,
          amount integer,
          balance_transaction text,
          billing_email text,
          created timestamptz,
          customer text,
          invoice text,
          payment_type text,
          receipt_email text,
          status text,
          updated timestamptz,
          data jsonb NOT NULL
        );
        CREATE INDEX IF NOT EXISTS svi_fixture_amount_idx ON stripe_charge_v1_fixture (amount);
        CREATE INDEX IF NOT EXISTS svi_fixture_balance_transaction_idx ON stripe_charge_v1_fixture (balance_transaction);
        CREATE INDEX IF NOT EXISTS svi_fixture_billing_email_idx ON stripe_charge_v1_fixture (billing_email);
        CREATE INDEX IF NOT EXISTS svi_fixture_created_idx ON stripe_charge_v1_fixture (created);
        CREATE INDEX IF NOT EXISTS svi_fixture_customer_idx ON stripe_charge_v1_fixture (customer);
        CREATE INDEX IF NOT EXISTS svi_fixture_invoice_idx ON stripe_charge_v1_fixture (invoice);
        CREATE INDEX IF NOT EXISTS svi_fixture_receipt_email_idx ON stripe_charge_v1_fixture (receipt_email);
        CREATE INDEX IF NOT EXISTS svi_fixture_status_idx ON stripe_charge_v1_fixture (status);
        CREATE INDEX IF NOT EXISTS svi_fixture_updated_idx ON stripe_charge_v1_fixture (updated);
      SQL
    end
  end

  down do
    run("DROP TABLE stripe_charge_v1_fixture") if ENV["RACK_ENV"] == "test"
  end
end
