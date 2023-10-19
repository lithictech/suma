# frozen_string_literal: true

require "sequel/all_or_none_constraint"
require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    if ENV["RACK_ENV"] == "test"
      run <<~SQL
                CREATE TABLE public.stripe_charge_v1_fixture (
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
      SQL
    end
  end

  down do
    run("DROP TABLE stripe_charge_v1_fixture") if ENV["RACK_ENV"] == "test"
  end
end
